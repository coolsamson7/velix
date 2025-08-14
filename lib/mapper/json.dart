import 'dart:collection';

import 'package:velix/validation/validation.dart';

import '../reflectable/reflectable.dart';
import 'mapper.dart';
import 'operation_builder.dart';

class JSONAccessor extends Accessor {
  // instance data

  Function? containerConstructor;

  // constructor

  JSONAccessor({required super.name, required super.type, required super.index, this.containerConstructor});

  // override

  @override
  MapperProperty makeTransformerProperty(bool write) {
    return JSONProperty(name: name); // TODO?
  }

  @override
  Function? getContainerConstructor() {
    return containerConstructor;
  }

  @override
  void resolve(Type type, bool write) {
  }
}

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

class JSON {
  // static data

  static Map<Type,JSONMapper> mappers = {};

  // internal

  static JSONMapper getMapper<T>() {
    var mapper = mappers[T];
    if ( mapper == null) {
      mappers[T] = mapper = JSONMapper<T>();
    }

    return mapper;
  }

  // static methods

  static Map serialize<T>(T instance) {
    return getMapper<T>().serialize(instance);
  }

  static dynamic deserialize<T>(Map json) {
    return getMapper<T>().deserialize<T>(json);
  }
}