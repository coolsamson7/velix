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
  Type getElementType() {
    return  Map<String,dynamic>;
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
  dynamic get(instance, MappingContext context) {
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
class JSONMapper {
  // instance data

  Type type;
  late Mapper serializer;
  late Mapper deserializer;
  late Mapping? serializerMapping;
  late Mapping? deserializerMapping;
  bool validate;

  // constructor

  JSONMapper({required this.type, this.validate = false}) {
    serializer = createSerializer();
    deserializer = createDeserializer();
  }

  // internal

  Mapper createSerializer() {
    Map<Type, MappingDefinition> mappings = {};
    var queue = Queue<Type>.from([type]);

    // local function

    void check(Type type) {
      if (!mappings.containsKey(type))
        queue.add(type);
    }

    MappingDefinition process(Type type) {
      var typeMapping = MappingDefinition<dynamic,Map<String, dynamic>>(sourceClass: type, targetClass: Map<String, dynamic>);
      var typeDescriptor = TypeDescriptor.forType(type);

      var jsonSerializable = typeDescriptor.find_annotation<JsonSerializable>() ?? JsonSerializable();

      mappings[type] = typeMapping;

      // process fields

      for (var field in typeDescriptor.getFields()) {
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
          var objectType = field.type as ObjectType;

          if ( objectType.typeDescriptor.isEnum()) {
            Convert? convertSource = JSON.instance.getConvert(field.type.type);

            typeMapping.map(from: field.name,
                to: JSONAccessor(name: json.name,
                    type: field.type.type,
                    convert: convertSource?.sourceConverter(),
                    includeNull: includeNull));
          }
          else {
            var target = objectType.type;

            check(target);

            typeMapping.map(
                from: field.name,
                to: JSONAccessor(name: json.name, type: Map<String, dynamic>, includeNull: includeNull),
                deep: true); // index?
          }
        } // if
        else {
          Convert? convertSource = JSON.instance.getConvert(field.type.type);

          typeMapping.map(from: field.name,
              to: JSONAccessor(name: json.name,
                  type: field.type.type,
                  convert: convertSource?.sourceConverter(),
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

    serializerMapping = mapper.getMappingX(type, Map<String,dynamic>);

    return mapper;
  }

  Mapper createDeserializer() {
    Map<Type, MappingDefinition> mappings = {};
    var queue = Queue<Type>.from([type]);

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
          var objectType = field.type as ObjectType;

          if ( !objectType.typeDescriptor.isEnum()) {
            var target = objectType.type;

            check(target);

            typeMapping.map(
                from: JSONAccessor(name: json.name, type: Map<String, dynamic>, includeNull: includeNull, defaultValue: defaultValue),
                to: field.name,
                deep: true);
          }
          else {
            Convert? convertSource = JSON.instance.getConvert(field.type.type);

            typeMapping.map(from: JSONAccessor(name: json.name,
                type: field.type.type,
                convert: convertSource?.targetConverter(),
                includeNull: includeNull,
                defaultValue: defaultValue),
                to: field.name,
                validate: validate);
          }

        } // if
        else {
          Convert? convertSource = JSON.instance.getConvert(field.type.type);

          typeMapping.map(from: JSONAccessor(name: json.name,
              type: field.type.type,
              convert: convertSource?.targetConverter(),
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

    deserializerMapping = mapper.mappings.values.firstWhere((mapping) => mapping.typeDescriptor.type == type);

    return mapper;
  }

  // public

  Map<String,dynamic> serialize(dynamic instance) {
    return serializer.map(instance, mapping: serializerMapping);
  }

  V deserialize<V>(Map<String,dynamic> json) {
    return deserializer.map(json, mapping: deserializerMapping);
  }
}


abstract class ConvertFactory<T,R> {
  Convert<T,R> getConvert(Type sourceType);

  bool accepts(Type t) {
    return false;
  }

  Type getReturnType() {
    return R;
  }
}

abstract class EnumConvertFactory<T extends Enum, R> extends ConvertFactory<T,R> {
  @override
  bool accepts(Type t) {
    return TypeDescriptor.forType(t).isEnum();
  }
}

class Enum2StringFactory<T extends Enum> extends EnumConvertFactory<T, String> {
  // instance data

  Map<Type, Convert> converters = {};

  // override

  @override
  Convert<T,String> getConvert(Type sourceType) {
    var result = converters[sourceType];
    if ( result == null) {
      var typeDescriptor = TypeDescriptor.forType(sourceType);
      List values = typeDescriptor.enumValues!;
      result = Convert<T, String>(
              (value) => (value as Enum).name,
            convertTarget: (str) =>
            values.firstWhere((c) => (c as Enum).name == str),
            sourceType: sourceType,
            targetType: String
      );
      converters[sourceType] = result;
    }

    return result as Convert<T,String>;
  }
}

/*class Enum2IndexFactory<T extends Enum> extends EnumConvertFactory<T, int> {
  // instance data

  Map<Type, Convert> converters = {};

  // override

  Convert<T,int> getConvert(Type t) {
    var result = converters[T];
    if ( result == null) {
      result = Convert<T, int>((value) => value.index, (index) => Color.values.firstWhere((c) => c.index == c) as T);
      converters[T] = result;
    }

    return result as Convert<T,int>;
  }
}*/

class Converters {
  // instance data

  List<Convert> converters = [];
  List<ConvertFactory> factories = [];

  // constructor

  Converters({required this.converters, required this.factories});

  Convert? getConvert(Type sourceType) {
    for ( Convert convert in converters)
      if ( convert.sourceType == sourceType )
        return convert ;

    for ( ConvertFactory factory in factories)
      if ( factory.accepts(sourceType)) {
        var convert = factory.getConvert(sourceType);

        converters.add(convert);

        return convert;
      }

    return null;
  }
}

/// Main class that offers serialize and deserialize methods
class JSON {
  // static data

  static JSON instance = JSON(validate: false);

  // instance data

  final bool validate;
  Map<Type,JSONMapper> mappers = {};
  Converters converters;

  // constructor List<Convert> converters = [];
  //   List<ConvertFactory>

  JSON({required this.validate, List<Convert>? converters, List<ConvertFactory>? factories}) : converters = Converters(converters: converters ?? [], factories: factories ?? []) {
    instance = this;

    // ugly... we need a type descriptor

    var fromMapConstructor = (Map<String,dynamic> args) => Map<String,dynamic>() ;
    var fromArrayConstructor = (List<dynamic> args) => Map<String,dynamic>() ;// TODO

    TypeDescriptor<Map<String, dynamic>>(name: "json" , annotations: [], fromArrayConstructor: fromArrayConstructor, fromMapConstructor: fromMapConstructor, constructor: ()=>HashMap<String,dynamic>(), constructorParameters: [], fields: []);
  }

  // internal

  Convert? getConvert(Type sourceType) {
    switch ( sourceType ) {
      case  int:
      case  double:
      case  bool:
      case  String:
        return null;
    }

    return converters.getConvert(sourceType);
  }

  JSONMapper getMapper(Type type) {
    var mapper = mappers[type];
    if ( mapper == null) {
      mappers[type] = mapper = JSONMapper(type: type, validate: validate);
    }

    return mapper;
  }

  // static methods

  /// serialize an instance to a 'JSON' map
  /// [instance] an instance
  static Map<String,dynamic> serialize(dynamic instance) {
    return JSON.instance.getMapper(instance.runtimeType).serialize(instance);
  }

  /// deserialize an 'JSON' to the specified class
  /// [T] the expected type
  /// [json] a 'JSON' map
  static dynamic deserialize<T>(Map<String,dynamic> json) {
    return JSON.instance.getMapper(T).deserialize<T>(json);
  }
}