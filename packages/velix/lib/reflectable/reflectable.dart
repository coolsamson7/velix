import '../util/collections.dart';
import '../validation/validation.dart';

Type nonNullableOf<T>() => T;

/// A `ClassAnnotation` can be used as the base class for type annotations
/// that will get its `apply` method executed by the infrastructure.
class ClassAnnotation {
  const ClassAnnotation();

  /// callback executed by the type infrastructure
  /// [type] the [TypeDescriptor] of the annotated class
  void apply(TypeDescriptor type){}
}

/// A `MethodAnnotation` can be used as the base class for method annotations
/// that will get its `apply` method executed by the infrastructure.
class MethodAnnotation {
  const MethodAnnotation();

  /// callback executed by the type infrastructure
  /// [type] the [TypeDescriptor] of the annotated class
  /// [method] the [MethodDescriptor] of the annotated method
  void apply(TypeDescriptor type, MethodDescriptor method){}
}

/// A `FieldAnnotation` can be used as the base class for field annotations
/// that will get its `apply` method executed by the infrastructure.
class FieldAnnotation {
  const FieldAnnotation();

  /// callback executed by the type infrastructure
  /// [type] the [TypeDescriptor] of the annotated class
  /// [method] the [FieldDescriptor] of the annotated field
  void apply(TypeDescriptor type, FieldDescriptor field){}
}

/// decorator used to mark classes that should emit meta-data
class Dataclass {
  const Dataclass();
}

/// decorator used to mark methods that should be considered by the generator
class Method {
  const Method();
}

/// decorator used to add meta-data to properties
class Attribute {
  final String type;

  /// [type] a type constraint
  const Attribute({this.type = ""});
}

typedef Getter<T, V> = V Function(T instance);
typedef Setter<T, V> = void Function(T instance, V value);

class AbstractDescriptor {
  // instance data

  final String name;
  final List<dynamic> annotations;

  // constructor

  AbstractDescriptor({required this.name, required this.annotations});

  // public

  bool hasAnnotation<A>() {
    return annotations.any((a) => a.runtimeType == A);
  }

  A? findAnnotation<A>() {
    return annotations.whereType<A>().firstOrNull;
  }
}

class AbstractPropertyDescriptor<T> extends AbstractDescriptor {
  // instance data

  late TypeDescriptor typeDescriptor;
  late AbstractType<dynamic, AbstractType> type;

  // constructor

  AbstractPropertyDescriptor({required super.name, required super.annotations});

  // internal

  void inferType(Type type, bool isNullable) {
    final Map<Type, AbstractType> types = {
      String: StringType(), // default unconstrained
      int: IntType(),
      double: DoubleType(),
      bool: BoolType(),
      DateTime: DateTimeType()
    };

    final Map<Type, AbstractType> nullableTypes = {
      String: StringType().optional(), // default unconstrained
      int: IntType().optional(),
      double: DoubleType().optional(),
      bool: BoolType().optional(),
      DateTime: DateTimeType().optional()
    };

    var result = isNullable ? nullableTypes[type] : types[type];

    if ( result == null)
      if ( type.toString().startsWith("List<")) {
        result = ListType(type);
        if ( isNullable )
          result = (result as dynamic).optional();
      }
      else {
        if ( TypeDescriptor.hasType(type)) {
          result = ObjectType(TypeDescriptor.forType(type));
          if ( isNullable )
            result = result.optional() as AbstractType<dynamic, AbstractType>?;
        }
        else {
          // it could be a class type or a object type that hasn't been constructed yet...

          TypePatch(type: type, applyFunc: (resolvedType) => this.type = resolvedType as dynamic);
          return;
        }
      }

    this.type = result as dynamic;
  }

  // public

  bool isField() => false;
  bool isMethod() => false;
}

class FieldDescriptor<T, V> extends AbstractPropertyDescriptor<T> {
  // instance data

  final Type? elementType;
  final Function? factoryConstructor;

  final Getter getter;
  final Setter? setter;
  final bool isNullable;

  bool get isFinal => setter == null;

  // constructor

  FieldDescriptor({
    required super.name,
    required super.annotations,
    this.elementType,
    this.factoryConstructor,
    required this.getter,
    this.setter,
    this.isNullable = false,
    AbstractType<dynamic, AbstractType>? type
  }) {
    if ( type != null)
      this.type = type;
    else
      inferType(V, isNullable);
  }

  // override

  @override
  bool isField() => true;

  // public

  V? get(T object) {
    return getter(object);
  }

  void set(T object, V value) {
    setter!(object, value);
  }

  bool isWriteable() {
    return setter != null;
  }
}

class MethodDescriptor<T,V> extends AbstractPropertyDescriptor<T> {
  // instance data

  final List<ParameterDescriptor> parameters;
  final bool isAsync;
  final bool isStatic;
  final Function? invoker;

  // constructor

  MethodDescriptor({
    required super.name,
    super.annotations = const [],

    required this.parameters,
    this.isAsync = false,
    this.isStatic = false,
    this.invoker,
  }) {
    inferType(V, false);
  }

  // override

  @override
  bool isMethod() => true;
}

class ParameterDescriptor extends AbstractDescriptor {
  // instance data

  final Type type;
  final bool isNamed;
  final bool isRequired;
  final bool isNullable;
  late dynamic defaultValue;

  // constructor

  ParameterDescriptor({
    required super.name,
    required super.annotations,

    required this.type,
    this.isNamed = false,
    this.isRequired = true,
    this.isNullable = false,
    defaultValue,
  }) {
    if ( isRequired && ![String,int,double,bool].contains(type) && !isNullable)
      this.defaultValue = this;
    else
      this.defaultValue = defaultValue;
  }

  // public

  bool hasDefault() {
      return defaultValue != this;
  }
}

class ConstructorDescriptor {
  final String? name; // null for default constructor
  final List<ParameterDescriptor> parameters;
  final Function factory;

  ConstructorDescriptor({
    this.name,
    required this.parameters,
    required this.factory,
  });
}

typedef Constructor<T> = Function;// T Function(Map<String, dynamic> args);//
typedef FromMapConstructor<T> = T Function(Map<String, dynamic> args);
typedef FromArrayConstructor<T> = T Function(List<dynamic> args);

typedef ApplyFunc<T> = Function(T arg);

abstract class Patch<T> {
  static List<Patch> patches = [];

  static void resolvePatches() {
    for ( var patch in patches)
      patch.apply();

    patches.clear();
  }

  // instance data

  ApplyFunc<T> applyFunc;

  // constructor

  Patch({required this.applyFunc}) {
    patches.add(this);
  }

  // public

  void apply() {
    applyFunc(resolve());
  }

  // abstract

  T resolve();
}

class TypePatch extends Patch<AbstractType> {
  Type type;

  // constructor

  TypePatch({required this.type, required super.applyFunc});

  // implement

  @override
  AbstractType resolve() {
    if (TypeDescriptor.hasType(type))
      return ObjectType(TypeDescriptor.forType(type));
    else
      return ClassType(type);
  }
}

DateTime cloneDateTime(DateTime d) {
  if (d.isUtc) {
    return DateTime.utc(
      d.year,
      d.month,
      d.day,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
      d.microsecond,
    );
  }
  return DateTime(
    d.year,
    d.month,
    d.day,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
    d.microsecond,
  );
}

/// Class covering the meta-data of a type.
/// [T] the reflected type
///
class TypeDescriptor<T> {
  // class methods

  static Iterable<TypeDescriptor> types() {
    return _byType.values;
  }

  static void register<T>(TypeDescriptor<T> typeDescriptor) {
    _byType[typeDescriptor.type] = typeDescriptor;
    _byName[typeDescriptor.location] = typeDescriptor;
  }

  /// Return a new or cached 'TypeDescriptor' given a type.
  /// [T] the reflected type
  static TypeDescriptor forType<T>([Type? type]) {
    final descriptor = _byType[type ?? T];
    if (descriptor == null) {
      throw StateError("No TypeDescriptor registered for type: $type");
    }

    return descriptor;
  }

  static void verify() {
    Patch.resolvePatches();
  }

  static bool hasType(Type type) {
    return _byType[type] != null;
  }

  static TypeDescriptor forName(String type) {
    final descriptor = _byName[type];
    if (descriptor == null) {
      throw StateError("No TypeDescriptor registered for type: $type");
    }

    return descriptor;
  }

  static T clone<T>(T instance) {
    // handle null

    //if (instance == null)
    //  return null;

    // handle enums and literals (String, int, double, bool, DateTime)

    if (instance is Enum || instance is String || instance is int || instance is double || instance is bool || instance is DateTime) {
      return instance;
    }

    // datetime

    if (instance is DateTime) {
      return cloneDateTime(instance) as T;
    }

    // types?

    if (TypeDescriptor.hasType(instance.runtimeType)) {
      var descriptor = TypeDescriptor.forType<T>();

      if (descriptor.isImmutable()) {
        Map<String, dynamic> params = {};

        for (var param in descriptor.constructorParameters)
          params[param.name] = clone(descriptor.get(instance as Object, param.name));

        return descriptor.fromMapConstructor!(params);
      }
      else {
        var result = descriptor.constructor!();

        for (var field in descriptor.getFields()) {
          if (field.factoryConstructor != null) { // TODO: Map, Set...
            var container = field.factoryConstructor!();

            for (var item in field.get(instance)) {
              container.add(clone(item));
            }

            field.set(result, container);
          }
          else field.set(result, clone(field.get(instance)));
        }

        return result;
      }
    }

    // any other class?

    return instance;
  }

  static bool deepEquals(Object a, Object? b) {
    if (identical(a, b))
      return true;

    if (b == null || b.runtimeType != a.runtimeType)
      return false;

    final typeDescriptor = TypeDescriptor.forType(a.runtimeType);

    for (final field in typeDescriptor.getFields()) {
      final valueA = field.getter(a);
      final valueB = field.getter(b);

      if ( field.type.runtimeType == ObjectType ) {
        if (!deepEquals(valueA, valueB))
          return false;
      }
      else if (field.type.runtimeType == ListType) {
        final listA = valueA as List?;
        final listB = valueB as List?;
        if (listA == null || listB == null) {
          if (listA != listB) return false;
          continue;
        }
        if (listA.length != listB.length) return false;
        for (var i = 0; i < listA.length; ++i) {
          if (!deepEquals(listA[i], listB[i])) return false;
        }
      }
      else if (valueA is Map && valueB is Map) {
        if (valueA.length != valueB.length) return false;
        for (final key in valueA.keys) {
          if (!valueB.containsKey(key)) return false;
          if (!deepEquals(valueA[key], valueB[key])) return false;
        }
      }
      else if (valueA is Set && valueB is Set) {
        if (valueA.length != valueB.length) return false;
        // Both must contain the same elements (unordered)
        for (final entry in valueA) {
          // Use `any` with deepEquals to handle nested set elements
          if (!valueB.any((b) => deepEquals(entry, b))) return false;
        }
      }
      else {
        if (valueA != valueB)
          return false;
      }
    }

    return true;
  }

  // class properties

  static final Map<Type,TypeDescriptor> _byType = {};
  static final Map<String,TypeDescriptor> _byName = {};

  // instance data

  String location;
  late Type type;

  final Map<String, AbstractPropertyDescriptor> _properties = {};

  Constructor<T>? constructor;
  FromMapConstructor<T>? fromMapConstructor;
  FromArrayConstructor<T>? fromArrayConstructor;
  List<ParameterDescriptor> constructorParameters;
  List<Object> annotations;
  List<T>? enumValues;
  bool isAbstract;
  late ObjectType<T> objectType;

  TypeDescriptor? superClass;
  List<TypeDescriptor> childClasses = [];

  // constructor

  TypeDescriptor({
    required this.location,
    required this.constructor,
    this.fromMapConstructor,
    this.fromArrayConstructor,
    required this.constructorParameters,
    required List<FieldDescriptor> fields,
    List<MethodDescriptor>? methods,
    required this.annotations,
    this.isAbstract = false,
    this.superClass,
    this.enumValues,
  }) {
    type = nonNullableOf<T>();

    TypeDescriptor.register(this);

    setup(fields, methods);
  }

  void setup(List<FieldDescriptor> fields, List<MethodDescriptor>? methods) {
    objectType = ObjectType(this);

    // super class

    if ( superClass != null) {
      superClass!.childClasses.add(this);

      // inherit properties

      for ( var inheritedProperty in superClass!.getProperties()) {
        _properties[inheritedProperty.name] = inheritedProperty;
      }
    }

    // own methods

    if ( methods != null)
      for (var method in methods) {
        method.typeDescriptor = this; // marker for a local method
        _properties[method.name] = method;

        // run annotations

        for ( var annotation in method.annotations)
          if ( annotation is MethodAnnotation)
            annotation.apply(this, method);
      } // for

    // own fields

    for (var field in fields) {
      field.typeDescriptor = this; // marker for a local field
      _properties[field.name] = field;

      // run annotations

      for ( var annotation in field.annotations)
        if ( annotation is FieldAnnotation)
          annotation.apply(this, field);
    } // for

    // run class annotations

    for ( var annotation in annotations)
      if ( annotation is ClassAnnotation)
        annotation.apply(this);
  }

  void validate(T instance) {
    objectType.validate(instance);
  }

  // internal

  //'asset:velix/test/main.dart:1:1:Collections',

  String get name {
    return type.toString();
  }

  String get file {
    int index = location.lastIndexOf('/');

    return location.substring(index + 1, location.indexOf(":", index));
  }

  int get line {
    int index = location.indexOf(':');
    index = location.indexOf(':', index + 1);
    var end = location.indexOf(':', index + 1);

    return int.parse(location.substring(index + 1,  end));
  }

  int get col {
    int index = location.indexOf(':');
    index = location.indexOf(':', index + 1);
    index = location.indexOf(':', index + 1);

    return int.parse(location.substring(index + 1));
  }

  A? getAnnotation<A>() {
    return findElement(annotations, (annotation) => annotation.runtimeType == A) as A?;
  }

  String get module {
    int index = location.lastIndexOf('/');
    return index == -1 ? location : location.substring(0, index);
  }

  FieldDescriptor _getField(String name) {
    final field = _properties[name];
    if (field == null)
      throw ArgumentError("No such field: $name");

    return field as FieldDescriptor;
  }

  // public

  bool hasInheritedClasses() {
    return childClasses.isNotEmpty;
  }

  bool isEnum() {
    return enumValues != null;
  }

  A? findAnnotation<A>() {
    return findElement(annotations, (annotation) => annotation is A) as A?;
  }

  // true, if all parameters have defaults ( either literal types or nullable object types )
  bool hasDefaultConstructor() {
    for (var constructorParam in constructorParameters)
      if ( !constructorParam.hasDefault())
        return false;

    return true;
  }

  /// return [true], if the type has at least one final field
  bool isImmutable() {
    return findElement(getFields(), (field) => field.isFinal) != null;
  }

  /// return the field names
  Iterable<String> getFieldNames() {
    return getFields().map((field) => field.name);
  }

  /// return [true], if the type has a named field
  /// [name] the field name
  bool hasField(String name) {
    return hasProperty(name);
  }

  /// return a named field.
  /// [name] the field name
  FieldDescriptor getField(String name) {
    return getProperty<FieldDescriptor>(name);
  }

  /// return a named field.
  /// [name] the field name
  FieldDescriptor? findField(String name) {
    return findProperty<FieldDescriptor>(name);
  }

  /// return all properties
  Iterable<AbstractPropertyDescriptor> getProperties() {
    return _properties.values;
  }

  /// return all fields
  Iterable<FieldDescriptor> getFields() {
    return _properties.values.whereType<FieldDescriptor>();
  }

  /// return all methods
  Iterable<MethodDescriptor> getMethods() {
    return _properties.values.whereType<MethodDescriptor>();
  }

  /// return a named property.
  /// [name] the field name
  P? findProperty<P>(String name) {
    return _properties[name] as P?;
  }

  /// return a named property.
  /// [name] the field name
  P getProperty<P extends AbstractPropertyDescriptor>(String name) {
    var property =  _properties[name];
    if ( property != null)
      return property as P;
    else
      throw Exception("unknown property $name");
  }

  /// return [true], if the type has a named property
  /// [name] the property name
  bool hasProperty<P>(String name) {
    return _properties[name] != null;
  }

  /// return [true], if the type has a named method
  /// [name] the method name
  bool hasMethod(String name) {
    return hasProperty<MethodDescriptor>(name);
  }

  /// return a named field.
  /// [name] the field name
  MethodDescriptor getMethod(String name) {
    return getProperty<MethodDescriptor>(name);
  }

  /// return the getter function of a specific field
  Getter getter(String field) {
    return _getField(field).getter;
  }

  /// return the setter function of a specific field
  Setter setter(String field) {
    return _getField(field).setter!;
  }

  /// get the field value of a specific instance
  /// [instance] the instance
  /// [field] the field name
  V get<V>(Object instance, String field) {
    return _getField(field).getter(instance);
  }

  /// set a field value
  /// [instance] the instance
  /// [field] the field name
  /// [value] a value
  void set(Object instance, String field, dynamic value) {
    _getField(field).setter!(instance, value);
  }
}

// some convenience functions for the generator

TypeDescriptor<T> type<T>({
  required String location,
  Constructor<T>? constructor,
  FromMapConstructor<T>? fromMapConstructor,
  FromArrayConstructor<T>? fromArrayConstructor,
  List<ParameterDescriptor>? params,
  List<FieldDescriptor>? fields,
  List<MethodDescriptor>? methods,
  TypeDescriptor? superClass,
  List<Object>? annotations,
  bool isAbstract = false
}) {
   TypeDescriptor<T>(location: location, isAbstract: isAbstract, constructor: constructor, fromArrayConstructor: fromArrayConstructor, fromMapConstructor: fromMapConstructor, annotations: annotations ?? [], constructorParameters: params ?? [], fields: fields ?? [], methods: methods, superClass: superClass);

   // it could be the lazy type

   return TypeDescriptor._byType[T]! as TypeDescriptor<T>;
}

TypeDescriptor<T> enumeration<T extends Enum>({
  required String name,
  required List<T> values,
  List<Object>? annotations,
}) {
  return TypeDescriptor<T>(location: name, constructor: () => null, annotations: annotations ?? [], constructorParameters: [], fields: [], enumValues: values);
}

ParameterDescriptor param<T>(String name, {
  bool isNamed = false,
  bool isRequired = false,
  bool isNullable = false,
  List<dynamic>? annotations,
  dynamic defaultValue}) {
  return ParameterDescriptor(name: name, type: T, isNamed: isNamed, isRequired: isRequired, isNullable: isNullable, defaultValue: defaultValue, annotations: annotations ?? []);
}

MethodDescriptor method<T,R>(String name, {List<ParameterDescriptor>? parameters, bool isAsync = false,
  bool isStatic = false,
  annotations = const [],
  required Function invoker}) {
  return MethodDescriptor<T,R>(name: name, parameters: parameters ?? [], annotations: annotations, invoker: invoker);
}

FieldDescriptor field<T,V>(String name, {
  AbstractType<V, AbstractType>? type,
  List<Object>? annotations,
  required Getter getter,
  Setter? setter,
  Type? elementType,
  Function? factoryConstructor,
  bool isFinal = false,
  bool isNullable = false
}) {
  return FieldDescriptor<T,V>(name: name, type: type, annotations: annotations ?? [], elementType: elementType, factoryConstructor: factoryConstructor, getter: getter, setter: setter, isNullable: isNullable);
}