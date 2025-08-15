import 'dart:collection';

import 'package:velix/validation/validation.dart';

import '../reflectable/reflectable.dart';
import 'mapper.dart';
import 'operation_builder.dart';


/// decorator used to influence the json serialization
class JsonSerializable {
  final bool includeNull;

  /// Create a JsonSerializable
  /// [includeNull] if true, nulls will be serialized.
  const JsonSerializable({this.includeNull = true});
}

/// decorator used to influence json serialization for fields
class Json {
  final String name;
  final bool ignore;
  final bool includeNull;
  final bool required;
  final Object? defaultValue;

  /// Create a Json
  /// [name] name override
  /// [ignore] if true, this field will not be serialized
  /// [includeNull]  if true, nulls will be serialized.
  /// [required] if true, the JSON is expected to have a value
  /// [defaultValue] default in case of a not supplied json value
  const Json({this.name = "", this.ignore = false, this.includeNull = true, this.required = true, this.defaultValue});
}

/// @internal
class JSONAccessor extends Accessor {
  // instance data

  Function? containerConstructor;
  bool includeNull;
  Object? defaultValue;

  // constructor

  JSONAccessor({required super.name, required super.type, super.index=0, this.containerConstructor, this.includeNull = true, this.defaultValue = JSONAccessor});

  // override

  @override
  MapperProperty makeTransformerProperty(bool write) {
    if ( defaultValue != JSONAccessor)
      return JSONProperty(name: name, includeNull: includeNull, defaultValue: defaultValue);
    else
      return JSONProperty(name: name, includeNull: includeNull, );
  }

  @override
  Function? getContainerConstructor() {
    return containerConstructor;
  }

  @override
  void resolve(Type type, bool write) {
  }
}

/// @internal
class JSONProperty extends MapperProperty {
  // instance data

  final String name;
  final bool includeNull;
  Function? containerConstructor;
  Object? defaultValue;

  // constructor

  JSONProperty({required this.name, this.containerConstructor, required this.includeNull, this.defaultValue = JSONProperty});

  // override

  @override
  dynamic get(dynamic instance, MappingContext context) {
    dynamic value =  (instance as Map)[name];

    if ( value == null) {
      if ( defaultValue != JSONProperty)
        return defaultValue;
      else
        throw MapperException("expected a value for $name");
    }

    return value;
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    if ( value == null ) {
      if (includeNull)
        (instance as Map)[name] = value;
    }
    else (instance as Map)[name] = value;
  }

  // override

  @override
  Type getType() {
    return Object; // TODO?
  }
}


/// @internal
class JSONMapper<T> {
  // instance data

  late Mapper serializer;
  late Mapper deserializer;
  bool validate;

  // constructor

  JSONMapper({this.validate = false}) {
    serializer = createSerializer();
    deserializer = createDeserializer();
  }

  // internal

  Mapper createSerializer() {
    Map<Type, MappingDefinition> mappings = {};
    var queue = Queue<Type>.from([T]);

    // local function

    void check(Type type) {
      if (!mappings.containsKey(type))
        queue.add(type);
    }

    MappingDefinition process(Type type) {
      var typeMapping = MappingDefinition<T,Map<String, dynamic>>(sourceClass: type, targetClass: Map<String, dynamic>);
      var typeDescriptor = TypeDescriptor.forType(type);

      var jsonSerializable = typeDescriptor.find_annotation<JsonSerializable>() ?? JsonSerializable();

      mappings[type] = typeMapping;

      // process fields

      for ( var field in typeDescriptor.getFields()) {
        var json = field.find_annotation<Json>() ?? Json(name: field.name, defaultValue: null);
        var includeNull = jsonSerializable.includeNull && json.includeNull != false;

        if ( json.ignore)
          continue;

        if (field.type is ListType) {
          var elementType = field.elementType;

          check(elementType!);

          typeMapping.map(
              from: field.name,
              to: JSONAccessor(name: json.name, type: Map<String, dynamic>, includeNull: includeNull, containerConstructor: () => []),
              deep: true); // index?
        }
        else if ( field.type is ObjectType) {
          var target = (field.type as ObjectType).type;

          check(target);

          typeMapping.map(
              from: field.name,
              to: JSONAccessor(name: json.name, type: Map<String, dynamic>, includeNull: includeNull),
              deep: true); // index?
        } // if
        else
          typeMapping.map(from: field.name, to: JSONAccessor(name: json.name, type: field.type.type, includeNull: includeNull));
      }

      return typeMapping;
    }

    // work on queue

    while (queue.isNotEmpty) {
      process(queue.removeFirst());
    }

    // done

    return Mapper(mappings.values.toList());
  }

  Mapper createDeserializer() {
    Map<Type, MappingDefinition> mappings = {};
    var queue = Queue<Type>.from([T]);

    // local function

    MappingDefinition process(Type type) {
      var typeMapping = MappingDefinition<Map<String, dynamic>, dynamic>(sourceClass: Map<String, dynamic>, targetClass: type);
      var typeDescriptor = TypeDescriptor.forType(type);

      var jsonSerializable = typeDescriptor.find_annotation<JsonSerializable>() ?? JsonSerializable();

      mappings[type] = typeMapping;

      void check(Type type) {
        if (!mappings.containsKey(type))
          queue.add(type);
      }

      // process fields

      for ( var field in typeDescriptor.getFields()) {
        var json = field.find_annotation<Json>() ?? Json(name: field.name, defaultValue: null);

        var includeNull = jsonSerializable.includeNull && json.includeNull != false;

        if ( json.ignore)
          continue;

        Object? defaultValue = JSONAccessor;
        if ( !json.required) {
          defaultValue = json.defaultValue;

          if ( !field.type.isValid(defaultValue))
            throw MapperException("the default $defaultValue for ${field.name} is not valid");
        }

        if (field.type is ListType) {
          var elementType = field.elementType;

          check(elementType!);

          typeMapping.map(
              from: JSONAccessor(name: json.name, type: List<dynamic>, includeNull: includeNull, defaultValue: defaultValue, containerConstructor: () => []),
              to: field.name,
              deep: true,
            validate: validate
          );
        }
        else if ( field.type is ObjectType) {
          var target = (field.type as ObjectType).type;

          check(target);

          typeMapping.map(
              from: JSONAccessor(name: json.name, type: Map<String, dynamic>, includeNull: includeNull, defaultValue: defaultValue),
              to: field.name,
              deep: true);
        } // if
        else
          typeMapping.map(from: JSONAccessor(name: json.name, type: field.type.type, includeNull: includeNull, defaultValue: defaultValue), to: field.name); // index?
      }

      return typeMapping;
    }

    // work on queue

    while (queue.isNotEmpty) {
      process(queue.removeFirst());
    }

    // done

    return Mapper(mappings.values.toList());
  }

  // public

  Map serialize(T instance) {
    return serializer.map<T,Map<String,dynamic>>(instance)!;
  }

  dynamic deserialize<T>(Map json) {
    return deserializer.map(json, mapping: deserializer.mappings.values.firstWhere((mapping) => mapping.typeDescriptor.type == T)) as T;
  }
}

/// Main class that offers serialize and deserialize methods
class JSON {
  // static data

  static JSON instance = JSON(validate: false);

  // instance data

  final bool validate;
  Map<Type,JSONMapper> mappers = {};

  // constructor

  JSON({required this.validate}) {
    instance = this;

    TypeDescriptor<Map<String, dynamic>>(name: "json" , annotations: [], constructor: ()=>HashMap<String,dynamic>(), constructorParameters: [], fields: []);
  }

  // internal

  JSONMapper getMapper<T>() {
    var mapper = mappers[T];
    if ( mapper == null) {
      mappers[T] = mapper = JSONMapper<T>(validate: validate);
    }

    return mapper;
  }

  // static methods

  /// serialize an instance to a 'JSON' map
  /// [instance] an instance
  static Map serialize<T>(T instance) {
    return JSON.instance.getMapper<T>().serialize(instance);
  }

  /// deserialize an 'JSON' to the specified class
  /// [T] the expected type
  /// [json] a 'JSON' map
  static dynamic deserialize<T>(Map json) {
    return JSON.instance.getMapper<T>().deserialize<T>(json);
  }
}