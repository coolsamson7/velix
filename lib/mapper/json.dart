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
  Function? getContainerConstructor() {
    return containerConstructor;
  }

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



// OLD

Map<String, dynamic> serializeToJson(Object obj) {
  final type = obj.runtimeType;
  final descriptor = TypeDescriptor.forType(type);


  final Map<String, dynamic> json = {};
  for (final field in descriptor.getFields()) {
    json[field.name] = field.getter(obj);
  }
  return json;
}

T deserializeFromJson<T>(Map<String, dynamic> json, T Function() creator) {
  final descriptor = TypeDescriptor.forType(T);

  final obj = creator();

  for (final field in descriptor.getFields()) {
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
    for (var field in descriptor.getFields()) {
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

    for (var field in descriptor.getFields()) {
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
