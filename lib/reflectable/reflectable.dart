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
    this.elementType,
    this.factoryConstructor,
    this.setter,
    this.isFinal = false,
    this.isNullable = false
  });

  // public

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

  // class properties

  static final Map<Type,TypeDescriptor> _byType = {};
  static final Map<String,TypeDescriptor> _byName = {};

  // instance data

  final String name;
  late Type type;
  final Map<String, FieldDescriptor> _fields = {};
  final Constructor<T> constructor;
  final List<ConstructorParameter> constructorParameters;

  // constructor

  TypeDescriptor({
    required this.name,
    required this.constructor,
    required this.constructorParameters,
    required List<FieldDescriptor> fields,
  }) {
    type = nonNullableOf<T>();

    for (var field in fields) {
        field.typeDescriptor = this;
        _fields[field.name] = field;
      }
    }

  // internal

  FieldDescriptor _getField(String name) {
    final field = _fields[name];
    if (field == null)
      throw ArgumentError("No such field: $name");

    return field;
  }

  // public

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

Map<String, dynamic> serializeToJson(Object obj) {
  final type = obj.runtimeType;
  final descriptor = TypeDescriptor.forType(type);


  final Map<String, dynamic> json = {};
  for (final field in descriptor._fields.values) {
    json[field.name] = field.getter(obj);
  }
  return json;
}

T deserializeFromJson<T>(Map<String, dynamic> json, T Function() creator) {
  final descriptor = TypeDescriptor.forType(T);

  final obj = creator();

  for (final field in descriptor._fields.values) {
    if (json.containsKey(field.name)) {
      field.setter!(obj as Object, json[field.name]);
    }
  }

  return obj;
}

class ObjectMapper {
  static Map<String, dynamic> toJson(Object obj,
      {Set<Object>? visited}) {
    visited ??= {};

    if (visited.contains(obj)) {
      return {'__ref': obj.hashCode.toString()};
    }

    visited.add(obj);

    final descriptor = TypeDescriptor.forType(obj.runtimeType);

    final map = <String, dynamic>{};
    for (var field in descriptor._fields.values) {
      final value = field.getter(obj);

      if (value == null || value is num || value is bool || value is String) {
        map[field.name] = value;
      }
      else if (value is List) {
        map[field.name] =
            value.map((e) => toJson(e, visited: visited)).toList();
      }
      else {
        map[field.name] = toJson(value, visited: visited);
      }
    }

    return map;
  }

  static Object fromJson(Type type, Map<String, dynamic> json,
      {Map<String, Object>? seen}) {
    seen ??= {};

    final descriptor = TypeDescriptor.forType(type);

    final instance = descriptor.constructor();

    for (var field in descriptor._fields.values) {
      final value = json[field.name];

      if (value is Map<String, dynamic>) {
        field.setter!(instance, fromJson(field.type.type, value, seen: seen));
      }
      else if (value is List &&
          field.type.toString().startsWith('List<')) {
        final elementType = field.type.toString();
        final resolvedType = TypeDescriptor.forName(elementType);

        final items = value
            .map((item) => item is Map<String, dynamic>
            ? fromJson(resolvedType.type, item, seen: seen)
            : item)
            .toList();
        field.setter!(instance, items);
      }
      else {
        field.setter!(instance, value);
      }
    }

    return instance;
  }
}

// some convenience functions for the generator

void type<T>({
  required String name,
  required Constructor<T> constructor,
  required List<ConstructorParameter> params,
  required List<FieldDescriptor> fields
}) {
  TypeDescriptor.register(TypeDescriptor<T>(name: name, constructor: constructor, constructorParameters: params, fields: fields));
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
    bool: BoolType()
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
  required Getter getter,
  Setter? setter,
  Type? elementType,
  Function? factoryConstructor,
  bool isFinal = false,
  bool isNullable = false
}) {
  return FieldDescriptor(name: name, type: inferType<V>(type), elementType: elementType, factoryConstructor: factoryConstructor, getter: getter, setter: setter, isFinal: isFinal, isNullable: isNullable);
}