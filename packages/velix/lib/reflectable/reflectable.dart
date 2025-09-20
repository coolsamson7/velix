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

/// decorator used to add meta-data to properties
class Attribute {
  final String type;

  /// [type] a type constraint
  const Attribute({this.type = ""});
}

typedef Getter<T, V> = V Function(T instance);
typedef Setter<T, V> = void Function(T instance, V value);

class FieldDescriptor<T, V> {
  // instance data

  final String name;
  final List<Object> annotations;
  final Type? elementType;
  final Function? factoryConstructor;

  AbstractType<V, AbstractType> type;
  final Getter<T, V> getter;
  final Setter<T, V>? setter;
  late TypeDescriptor typeDescriptor;
  final bool isNullable;

  bool get isFinal => setter == null;

  // constructor

  FieldDescriptor({
    required this.name,
    required this.type,
    required this.getter,
    required this.annotations,
    this.elementType,
    this.factoryConstructor,
    this.setter,
    this.isNullable = false,
  });


  // public

  A? findAnnotation<A>() {
    return findElement(annotations, (annotation) => annotation is A) as A?;
  }

  bool isWriteable() {
    return setter != null;
  }
}

class MethodDescriptor {
  // instance data

  final String name;
  final Type returnType;
  final List<ParameterDescriptor> parameters;
  final bool isAsync;
  final bool isStatic;
  final List<dynamic> annotations;
  final Function? invoker;
  late TypeDescriptor typeDescriptor;

  // constructor

  MethodDescriptor({
    required this.name,
    required this.returnType,
    required this.parameters,
    this.isAsync = false,
    this.isStatic = false,
    this.annotations = const [],
    this.invoker,
  });

  bool hasAnnotation<T>() {
    return annotations.any((a) => a.runtimeType == T);
  }

  T? findAnnotation<T>() {
    return annotations.whereType<T>().firstOrNull;
  }
}

class ParameterDescriptor {
  // instance data

  final String name;
  final Type type;
  final bool isNamed;
  final bool isRequired;
  final bool isNullable;
  late dynamic defaultValue;
  final List<dynamic> annotations;

  // constructor

  ParameterDescriptor({
    required this.name,
    required this.type,
    required this.annotations,
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

  T? getAnnotation<T>() {
    return findElement(annotations, (annotation) => annotation.runtimeType == T) as T?;
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
      return TypeDescriptor<T>.lazy();

      //throw StateError("No TypeDescriptor registered for type: $type");
    }

    return descriptor;
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

  bool lazy = false;
  String location;
  late Type type;
  final Map<String, FieldDescriptor> _fields = {};
  final Map<String, MethodDescriptor> _methods = {};
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

  TypeDescriptor.lazy() :this(
      location: "",
      constructor: null,
      fromMapConstructor: null,
      fromArrayConstructor: null,
      constructorParameters: [],
      fields: [],
      methods: null,
      annotations: [],
      lazy: true
  ) ;

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
    this.lazy = false
  }) {
    type = nonNullableOf<T>();

    var existing = _byType[T];

    if ( existing != null) {
      existing.location = location;
      existing.constructor = constructor;
      existing.fromMapConstructor = fromMapConstructor;
      existing.fromArrayConstructor = fromArrayConstructor;
      existing.constructorParameters = constructorParameters;
      existing.annotations = annotations;
      existing.isAbstract = isAbstract;
      existing.superClass = superClass;
      existing.enumValues = enumValues;
      existing.lazy = false;

      existing.setup(fields, methods);
    }
    else {
      TypeDescriptor.register(this);

      if ( !lazy )
        setup(fields, methods);
    }
  }

  void setup(List<FieldDescriptor> fields, List<MethodDescriptor>? methods) {
    objectType = ObjectType(this);

    // super class

    if ( superClass != null) {
      superClass!.childClasses.add(this);

      // inherit fields

      for ( var inheritedField in superClass!.getFields()) {
        _fields[inheritedField.name] = inheritedField;
      }

      // inherit methods

      for ( var inheritedMethod in superClass!.getMethods()) {
        _methods[inheritedMethod.name] = inheritedMethod;
      }
    }

    // own methods

    if ( methods != null)
      for (var method in methods) {
        method.typeDescriptor = this; // marker for a local method
        _methods[method.name] = method;

        // run annotations

        for ( var annotation in method.annotations)
          if ( annotation is MethodAnnotation)
            annotation.apply(this, method);
      } // for

    // own fields

    for (var field in fields) {
      field.typeDescriptor = this; // marker for a local field
      _fields[field.name] = field;

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

  T? getAnnotation<T>() {
    return findElement(annotations, (annotation) => annotation.runtimeType == T) as T?;
  }

  String get module {
    int index = location.lastIndexOf('/');
    return index == -1 ? location : location.substring(0, index);
  }

  FieldDescriptor _getField(String name) {
    final field = _fields[name];
    if (field == null)
      throw ArgumentError("No such field: $name");

    return field;
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
    return findElement(_fields.values.toList(), (field) => field.isFinal)!= null;
  }

  /// return the field names
  List<String> getFieldNames() {
    return _fields.keys.toList();
  }

  /// return [true], if the type has a named field
  /// [name] the field name
  bool hasField(String name) {
    return _fields[name] != null;
  }

  /// return a named field.
  /// [name] the field name
  FieldDescriptor getField(String name) {
    var field = _fields[name];
    if ( field != null)
      return field;
    else
      throw Exception("unknown field $type.$name");
  }

  /// return all fields
  Iterable<FieldDescriptor> getFields() {
    return _fields.values;
  }

  /// return all fields
  Iterable<MethodDescriptor> getMethods() {
    return _methods.values;
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

/// @internal
dynamic inferType<T>(AbstractType<T,AbstractType>? t, bool isNullable) {
  if ( t != null)
    return t;

  final type = nonNullableOf<T>();

  final Map<Type, AbstractType> types = {
    String: StringType(),    // default unconstrained
    int: IntType(),
    double: DoubleType(),
    bool: BoolType(),
    DateTime: DateTimeType()
  };

  final Map<Type, AbstractType> nullableTypes = {
    String: StringType().optional(),    // default unconstrained
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
      result = ObjectType(TypeDescriptor.forType<T>());
      if ( isNullable )
        result = (result as dynamic).optional();
    }

   return result as dynamic;
}

MethodDescriptor method<T,R>(String name, {List<ParameterDescriptor>? parameters, bool isAsync = false,
  bool isStatic = false,
  annotations = const [],
  required Function invoker}) {
  return MethodDescriptor(name: name, returnType: R, parameters: parameters ?? [], annotations: annotations, invoker: invoker);
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
  return FieldDescriptor(name: name, type: inferType<V>(type, isNullable), annotations: annotations ?? [], elementType: elementType, factoryConstructor: factoryConstructor, getter: getter, setter: setter, isNullable: isNullable);
}