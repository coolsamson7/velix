import '../util/collections.dart';
import '../validation/validation.dart';

Type nonNullableOf<T>() => T;

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

  final AbstractType<V> type;
  final Getter<T, V> getter;
  final Setter<T, V>? setter;
  late TypeDescriptor typeDescriptor;
  final bool isFinal;
  final bool isNullable;

  // constructor

  FieldDescriptor({
    required this.name,
    required this.type,
    required this.getter,
    required this.annotations,
    this.elementType,
    this.factoryConstructor,
    this.setter,
    this.isFinal = false,
    this.isNullable = false,
  });

  // public

  T? find_annotation<T>() {
    return findElement(annotations, (annotation) => annotation is T) as T?;
  }

  bool isWriteable() {
    return setter != null;
  }
}

class ConstructorParameter {
  // instance data

  final String name;
  final Type type;
  final bool isNamed;
  final bool isRequired;
  final bool isNullable;
  late dynamic defaultValue;

  // constructor

  ConstructorParameter({
    required this.name,
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
  final List<ConstructorParameter> parameters;
  final Function factory;

  ConstructorDescriptor({
    this.name,
    required this.parameters,
    required this.factory,
  });
}

typedef Constructor<T> = Function;// T Function(Map<String, dynamic> args);//

/// Class covering the meta-data of a type.
/// [T] the reflected type
///
class TypeDescriptor<T> {
  // class methods

  static void register<T>(TypeDescriptor<T> typeDescriptor) {
    _byType[typeDescriptor.type] = typeDescriptor;
    _byName[typeDescriptor.name] = typeDescriptor;
  }

  /// Return a new or cached 'TypeDescriptor' given a type.
  /// [T] the reflected type
  static TypeDescriptor forType<T>(T type) {
    final descriptor = _byType[type];
    if (descriptor == null) {
      throw StateError("No TypeDescriptor registered for type: $type");
    }

    return descriptor;
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
      /* TODO if (valueA is List && valueB is List) {
        if (!equality.equals(valueA, valueB)) return false;
      }
      else if (valueA is Map && valueB is Map) {
        if (!equality.equals(valueA, valueB)) return false;
      }
      else if (valueA is Set && valueB is Set) {
        if (!equality.equals(valueA, valueB)) return false;
      } */
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

  final String name;
  late Type type;
  final Map<String, FieldDescriptor> _fields = {};
  final Constructor<T> constructor;
  final List<ConstructorParameter> constructorParameters;
  final List<Object> annotations;
  final List<T>? enumValues;

  // constructor

  TypeDescriptor({
    required this.name,
    required this.constructor,
    required this.constructorParameters,
    required List<FieldDescriptor> fields,
    required this.annotations,
    this.enumValues
  }) {
    type = nonNullableOf<T>();

    for (var field in fields) {
        field.typeDescriptor = this;
        _fields[field.name] = field;
      } // for

    // automatically register

    TypeDescriptor.register(this);
  }

  // internal

  FieldDescriptor _getField(String name) {
    final field = _fields[name];
    if (field == null)
      throw ArgumentError("No such field: $name");

    return field;
  }

  // public

  bool isEnum() {
    return this.enumValues != null;
  }

  T? find_annotation<T>() {
    return findElement(annotations, (annotation) => annotation is T) as T?;
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
  /// [field] the field name
  bool hasField(String field) {
    return _fields[field] != null;
  }

  /// return a named field.
  /// [field] the field name
  FieldDescriptor getField(String field) {
    return _fields[field]!;
  }

  /// return all fields
  Iterable<FieldDescriptor> getFields() {
    return _fields.values;
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
  dynamic get(Object instance, String field) {
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

void type<T>({
  required String name,
  required Constructor<T> constructor,
  required List<ConstructorParameter> params,
  required List<FieldDescriptor> fields,
  List<Object>? annotations,
}) {
  TypeDescriptor<T>(name: name, constructor: constructor, annotations: annotations ?? [], constructorParameters: params, fields: fields);
}

void enumeration<T extends Enum>({
  required String name,
  required List<T> values,
  List<Object>? annotations,
}) {
  TypeDescriptor<T>(name: name, constructor: () => null, annotations: annotations ?? [], constructorParameters: [], fields: [], enumValues: values);
}

ConstructorParameter param<T>(String name, {
  bool isNamed = false,
  bool isRequired = false,
  bool isNullable = false,
  dynamic defaultValue}) {
  return ConstructorParameter(name: name, type: T, isNamed: isNamed, isRequired: isRequired, isNullable: isNullable, defaultValue: defaultValue);
}

/// @internal
AbstractType inferType<T>(AbstractType? t) {
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

  var result = types[type];

  if ( result == null)
    if ( type.toString().startsWith("List<"))
      return ListType(type);
    else
      return ObjectType(type);
  else
    return types[type]!;
}

FieldDescriptor field<T,V>(String name, {
  AbstractType<V>? type,
  List<Object>? annotations,
  required Getter getter,
  Setter? setter,
  Type? elementType,
  Function? factoryConstructor,
  bool isFinal = false,
  bool isNullable = false
}) {
  return FieldDescriptor(name: name, type: inferType<V>(type), annotations: annotations ?? [], elementType: elementType, factoryConstructor: factoryConstructor, getter: getter, setter: setter, isFinal: isFinal, isNullable: isNullable);
}