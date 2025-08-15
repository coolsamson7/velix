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
  Converter? convert;

  // constructor

  JSONAccessor({required super.name, required super.type, super.index=0, this.containerConstructor, this.includeNull = true, this.defaultValue = JSONAccessor, this.convert});

  // override

  @override
  MapperProperty makeTransformerProperty(bool write) {
    if ( defaultValue != JSONAccessor) {
      if ( convert != null)
        return ConvertingJSONProperty(name: name, includeNull: includeNull, defaultValue: defaultValue, convert: convert!, type: this.type); // TODO
      else
        return JSONProperty(
          name: name, includeNull: includeNull, defaultValue: defaultValue, type: this.type);
    }
    else {
      if ( convert != null)
        return ConvertingJSONProperty(name: name, includeNull: includeNull, convert: convert!, type: this.type); // TODO
      else
        return JSONProperty(name: name, includeNull: includeNull,type: this.type);
    }
  }

  @override
  Function? getContainerConstructor() {
    return containerConstructor;
  }

  @override
  void resolve(Type type, bool write) {
  }
}

class ConvertingJSONProperty extends JSONProperty {
  // instance data

  Converter convert;

  // constructor

  ConvertingJSONProperty({required this.convert, required super.name, required super.type, required super.includeNull, super.containerConstructor, super.defaultValue=JSONProperty});

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

    return convert(value);
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    if ( value == null ) {
      if (includeNull)
        (instance as Map)[name] = value;
    }
    else (instance as Map)[name] = convert(value);
  }
}

/// @internal
class JSONProperty extends MapperProperty {
  // instance data

  final String name;
  final bool includeNull;
  Function? containerConstructor;
  Object? defaultValue;
  final Type type;

  // constructor

  JSONProperty({required this.name, required this.type, this.containerConstructor, required this.includeNull, this.defaultValue = JSONProperty});

  // override

  @override
  dynamic get(dynamic instance, MappingContext context) {
    dynamic value = (instance as Map)[name];

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
    return type;
  }
}


/// @internal
class JSONMapper<T> {
  // instance data

  late Mapper serializer;
  late Mapper deserializer;
  late Mapping? serializerMapping;
  late Mapping? deserializerMapping;
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
        else {
          Converter? convertSource;

          if ( field.type.type == DateTime) {
            convertSource = JSON.instance.typeConversions.getConverter(DateTime, String);
          }

          typeMapping.map(from: field.name,
              to: JSONAccessor(name: json.name,
                  type: field.type.type,
                  convert: convertSource,
                  includeNull: includeNull));
        }
      }

      return typeMapping;
    }

    // work on queue

    while (queue.isNotEmpty) {
      process(queue.removeFirst());
    }

    // done

    var mapper = Mapper(mappings.values.toList());

    serializerMapping = mapper.getMappingX(T, Map<String,dynamic>);

    return mapper;
  }

  Mapper createDeserializer() {
    Map<Type, MappingDefinition> mappings = {};
    var queue = Queue<Type>.from([T]);

    // local function

    MappingDefinition process(Type type) {
      var typeMapping = MappingDefinition<Map<String, dynamic>, dynamic>(sourceClass: Map<String, dynamic>, targetClass: type);

      //if ( mapping == null)
      //  mapping = typeMapping;

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
        else {
          Converter? convertSource;

          if ( field.type.type == DateTime) {
            convertSource = JSON.instance.typeConversions.getConverter(String, DateTime);
          }

          typeMapping.map(from: JSONAccessor(name: json.name,
              type: field.type.type,
              convert: convertSource,
              includeNull: includeNull,
              defaultValue: defaultValue),
              to: field.name,
            validate: validate);
        }
      }

      return typeMapping;
    }

    // work on queue

    while (queue.isNotEmpty) {
      process(queue.removeFirst());
    }

    // done

    var mapper = Mapper(mappings.values.toList());

    deserializerMapping = mapper.mappings.values.firstWhere((mapping) => mapping.typeDescriptor.type == T);

    return mapper;
  }

  // public

  Map serialize(T instance) {
    return serializer.map(instance, mapping: serializerMapping);
  }

  V deserialize<V>(Map json) {
    return deserializer.map(json, mapping: deserializerMapping);
  }
}

/// Main class that offers serialize and deserialize methods
class JSON {
  // static data

  static JSON instance = JSON(validate: false);

  // instance data

  final bool validate;
  Map<Type,JSONMapper> mappers = {};
  TypeConversions typeConversions = TypeConversions();

  // constructor

  JSON({required this.validate, List<Convert>? converters}) {
    instance = this;
    
    if ( converters != null)
      for ( var converter in converters)
        typeConversions.register(converter);
    
    // add some defaults
    
    if (typeConversions.getConverter(String, DateTime) == null)
      typeConversions.register(Convert<String,DateTime>((value) => DateTime.parse(value)));

    if (typeConversions.getConverter(DateTime,String) == null)
      typeConversions.register(Convert<DateTime,String>((value) => value.toIso8601String()));
    
    // ugly... we need a type descriptor

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