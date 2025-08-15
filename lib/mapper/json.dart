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

  // constructor

  JSONAccessor({required super.name, required super.type, required super.index, this.containerConstructor});

  // override

  @override
  MapperProperty makeTransformerProperty(bool write) {
    return JSONProperty(name: name);
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
  Function? containerConstructor;

  // constructor

  JSONProperty({required this.name, this.containerConstructor});

  // override

  @override
  dynamic get(dynamic instance, MappingContext context) {
    return (instance as Map)[name];
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    (instance as Map)[name] = value;
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

  // constructor

  JSONMapper() {
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

      mappings[type] = typeMapping;

      // process fields

      for ( var field in typeDescriptor.getFields()) {
        if (field.type is ListType) {
          var elementType = field.elementType;

          check(elementType!);

          typeMapping.map(from: field.name,
              to: JSONAccessor(
                  name: field.name, type: Map<String, dynamic>, index: 0, containerConstructor: () => []),
              deep: true); // index?
        }
        else if ( field.type is ObjectType) {
          var target = (field.type as ObjectType).type;

          check(target);

          typeMapping.map(from: field.name,
              to: JSONAccessor(
                  name: field.name, type: Map<String, dynamic>, index: 0),
              deep: true); // index?
        } // if
        else
          typeMapping.map(from: field.name, to: JSONAccessor(name: field.name, type: field.type.type, index: 0)); // index?
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

      mappings[type] = typeMapping;

      void check(Type type) {
        if (!mappings.containsKey(type))
          queue.add(type);
      }

      // process fields

      for ( var field in typeDescriptor.getFields()) {
        if (field.type is ListType) {
          var elementType = field.elementType;

          check(elementType!);

          typeMapping.map(
              from: JSONAccessor(name: field.name, type: List<dynamic>, index: 0, containerConstructor: () => []),
              to: field.name,
              deep: true);
        }
        else if ( field.type is ObjectType) {
          var target = (field.type as ObjectType).type;

          check(target);

          typeMapping.map(
              from: JSONAccessor(
                  name: field.name, type: Map<String, dynamic>, index: 0),
              to: field.name,
              deep: true);
        } // if
        else
          typeMapping.map(from: JSONAccessor(name: field.name, type: field.type.type, index: 0), to: field.name); // index?
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
///
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
      mappers[T] = mapper = JSONMapper<T>();
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