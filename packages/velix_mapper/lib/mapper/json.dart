import 'dart:collection';

import 'package:velix/validation/validation.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'mapper.dart';
import 'operation_builder.dart';


// annotations

/// decorator used to influence the json serialization
class JsonSerializable {
  final bool includeNull;
  final String discriminator;
  final String discriminatorField;

  /// Create a JsonSerializable
  /// [includeNull] if true, nulls will be serialized.
  const JsonSerializable({this.includeNull = true, this.discriminator = "", this.discriminatorField = ""});
}

/// decorator used to influence json serialization for fields
class Json {
  final String name;
  final bool ignore;
  final bool includeNull;
  final bool required;
  final Object? defaultValue;
  final Type? converter;

  /// Create a Json
  /// [name] name override
  /// [ignore] if true, this field will not be serialized
  /// [includeNull]  if true, nulls will be serialized.
  /// [required] if true, the JSON is expected to have a value
  /// [defaultValue] default in case of a not supplied json value
  const Json({this.name = "", this.converter,  this.ignore = false, this.includeNull = true, this.required = true, this.defaultValue});
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

// TODO TEST

class PolymorphicMapping extends Mapping<Map<String, dynamic>,dynamic> {
  // instance data

  String field;

  Map<String,Mapping> mappings = {};

  // constructor

  PolymorphicMapping({required this.field, required super.mapper, required super.typeDescriptor, required super.constructor, required super.stackSize, required super.intermediateResultDefinitions, required super.definition, required super.operations, required super.finalizer}) {
    //setup();
  }

  // internal

  void setup() {
    if ( typeDescriptor.findAnnotation<JsonSerializable>()?.discriminator != null)
      mappings[typeDescriptor.findAnnotation<JsonSerializable>()!.discriminator] = this;

    for (var subClass in typeDescriptor.childClasses) {
      var discriminator = subClass.findAnnotation<JsonSerializable>()!.discriminator;

      mappings[discriminator] = mapper.getMappingX(Map<String, dynamic>, subClass.type);
    }
  }

  Mapping findMapping(Map<String, dynamic> data) {
    if ( mappings.isEmpty)
      setup();

    var discriminator = data[field];

    return mappings[discriminator]!;
  }

  // override

  @override
  void transformTarget(dynamic source, dynamic target, MappingContext context) {
    var mapping = findMapping(source as Map<String,dynamic>);

    if ( mapping == this)
       super.transformTarget(source, target, context);
    else {
      mapping.setupContext(context);
      mapping.transformTarget(source, target, context);
    }
  }
}

class PolymorphicMappingDefinition extends MappingDefinition<Map<String, dynamic>,dynamic> {
  String field;

  // constructor

  PolymorphicMappingDefinition({required this.field, required Type targetClass}) : super(sourceClass: Map<String, dynamic>, targetClass: targetClass);

  // override

  Mapping<Map<String, dynamic>,dynamic> createMapping(Mapper mapper) {
    var result = createOperations(mapper);

    // validate

    for ( var intermediateResult in intermediateResultDefinitions)
      if ( intermediateResult.missing > 0) {
        throw MapperException("${ intermediateResult.typeDescriptor.type} misses ${intermediateResult.missing} arguments");
      }

    return PolymorphicMapping(
        field: field,
        mapper: mapper,
        definition: this,
        operations: result.operations,
        typeDescriptor: TypeDescriptor.forType(targetClass),
        constructor: result.constructor,
        stackSize: result.stackSize,
        intermediateResultDefinitions: intermediateResultDefinitions,
        finalizer: collectFinalizer());
   }
}

// TEST

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
      if ( !TypeDescriptor.hasType(type))
        return;

      // own class

      if (!mappings.containsKey(type)) {
        queue.add(type);

        // check subclasses as well

        for ( var sub in TypeDescriptor.forType(type).childClasses)
          check(sub.type);
      }
    }

    MappingDefinition process(Type type) {
      var typeMapping = MappingDefinition<dynamic,Map<String, dynamic>>(sourceClass: type, targetClass: Map<String, dynamic>);
      var typeDescriptor = TypeDescriptor.forType(type);

      var jsonSerializable = typeDescriptor.findAnnotation<JsonSerializable>() ?? JsonSerializable();

      mappings[type] = typeMapping;

      // process fields

      for (var field in typeDescriptor.getFields()) {
        var json = field.findAnnotation<Json>() ?? Json(name: field.name, defaultValue: null);
        var includeNull = jsonSerializable.includeNull && json.includeNull != false;

        if ( json.ignore)
          continue;

        var jsonField = json.name;
        if (jsonField.isEmpty)
          jsonField = field.name;

        if (field.type is ListType) {
          var elementType = field.elementType;

          check(elementType!);

          typeMapping.map(
              from: field.name,
              to: JSONAccessor(
                  name: jsonField,
                  type: Map<String, dynamic>,
                  includeNull: includeNull,
                  containerConstructor: () => []
              ),
              deep: true
          ); // index?
        }
        else if ( field.type is ObjectType) {
          var objectType = field.type as ObjectType;

          if ( objectType.typeDescriptor.isEnum()) {
            Convert? convertSource = JSON.instance.getConvert(field.type.type);

            typeMapping.map(
                from: field.name,
                to: JSONAccessor(
                    name: jsonField,
                    type: field.type.type,
                    convert: convertSource?.sourceConverter(),
                    includeNull: includeNull
                )
            );
          }
          else {
            var target = objectType.type;

            // manual converter?

            Convert? convert ;
            if ( json.converter != null) {
              convert = JSON.getConvert4(json.converter!);
            }
            else convert = JSON.instance.getConvert(field.type.type);

            if ( convert == null)
              check(target);

            typeMapping.map(
                convert: convert,
                from: field.name,
                to: JSONAccessor(
                    name: jsonField,
                    type: Map<String, dynamic>,
                    includeNull: includeNull,
                    //convert: convert?.sourceConverter()
                ),
                deep: convert == null,
                validate: validate
            ); // index?
          }
        } // if
        else {
          Convert? convert ;
          if ( json.converter != null) {
            convert = JSON.getConvert4(json.converter!);
          }
          else convert = JSON.instance.getConvert(field.type.type);

          typeMapping.map(
              from: field.name,
              to: JSONAccessor(
                  name: jsonField,
                  type: field.type.type,
                  convert: convert?.sourceConverter(),
                  includeNull: includeNull
              ),
              validate: validate
          );
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
      var typeDescriptor = TypeDescriptor.forType(type);

      var jsonSerializable = typeDescriptor.findAnnotation<JsonSerializable>() ?? JsonSerializable();

      MappingDefinition typeMapping;

      if (jsonSerializable.discriminatorField.isNotEmpty)
        typeMapping = PolymorphicMappingDefinition(field:  jsonSerializable.discriminatorField, targetClass: type);
      else
        typeMapping = MappingDefinition(sourceClass: Map<String, dynamic>, targetClass: type);

      mappings[type] = typeMapping;

      // local function

      void check(Type type) {
        if ( !TypeDescriptor.hasType(type))
          return;

        if (!mappings.containsKey(type)) {
          queue.add(type);

          // check all subclasses as well

          for ( var sub in TypeDescriptor.forType(type).childClasses)
            check(sub.type);
        }
      }

      for ( var sub in TypeDescriptor.forType(type).childClasses)
        check(sub.type);

      // process fields

      for ( var field in typeDescriptor.getFields()) {
        var json = field.findAnnotation<Json>() ?? Json(name: field.name, defaultValue: null);

        var includeNull = jsonSerializable.includeNull && json.includeNull != false;

        if ( json.ignore)
          continue;

        var jsonField = json.name;
        if (jsonField.isEmpty)
          jsonField = field.name;

        Object? defaultValue = JSONAccessor;
        if ( !json.required) {
          defaultValue = json.defaultValue;

          //if ( !field.type.isValid(defaultValue))
          //  throw MapperException("the default $defaultValue for ${field.name} is not valid"); // TODO?
        }

        if (field.type is ListType) {
          var elementType = field.elementType;

          check(elementType!);

          typeMapping.map(
              from: JSONAccessor(
                  name: jsonField,
                  type: List<dynamic>,
                  includeNull: includeNull,
                  defaultValue: defaultValue,
                  containerConstructor: () => []
              ),
              to: field.name,
              deep: true,
              validate: validate
          );
        }
        else if ( field.type is ObjectType) {
          var objectType = field.type as ObjectType;

          Convert? convert ;
          if ( json.converter != null) {
            convert = JSON.getConvert4(json.converter!);
          }
          else convert = JSON.instance.getConvert(field.type.type);

          if ( !objectType.typeDescriptor.isEnum() && convert == null) {
            var target = objectType.type;

            check(target);

            typeMapping.map(
                from: JSONAccessor(
                    name: jsonField,
                    type: Map<String, dynamic>,
                    includeNull: includeNull,
                    defaultValue: defaultValue
                ),
                //validate: validate,
                to: field.name,
                deep: true
            );
          }
          else {
            // manual converter?

            typeMapping.map(
                //convert: convert,
                from: JSONAccessor(
                    name: jsonField,
                    type: field.type.type,
                    convert: convert?.targetConverter(),
                    includeNull: includeNull,
                    defaultValue: defaultValue,
                ),
                to: field.name,
                deep: convert == null,
                validate: validate
            );
          }
        } // if
        else {
          Convert? convert ;
          if ( json.converter != null) {
            convert = JSON.getConvert4(json.converter!);
          }
          else convert = JSON.instance.getConvert(field.type.type);

          typeMapping.map(
              from: JSONAccessor(
                  name: jsonField,
                  type: field.type.type,
                  convert: convert?.targetConverter(),
                  includeNull: includeNull,
                  defaultValue: defaultValue
              ),
              to: field.name,
              //convert: convert,
              validate: validate
          );
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
      Map<String,T> mappings = HashMap<String,T>();

      for ( T e in typeDescriptor.enumValues!)
        mappings[e.name] = e;

      result = Convert<T, String>(
            convertSource: (value) => (value as Enum).name,
            convertTarget: (str) => mappings[str]!,
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

  static Map<Type,Convert>  type2Converters = {};

  static Convert getConvert4(Type type) {
    Convert? result = type2Converters[type];

    if ( result == null) {
      var descriptor = TypeDescriptor.forType(type);
      var instance = descriptor.constructor!();

      if (instance is Convert) {
        result = instance;
        type2Converters[type] = instance;
      }
      else
        throw Exception("not a convert");
    }

    return result;
  }

  // instance data

  final bool validate;
  Map<Type,JSONMapper> mappers = {};
  Converters converters;

  // constructor

  JSON({required this.validate, List<Convert>? converters, List<ConvertFactory>? factories}) : converters = Converters(converters: converters ?? [], factories: factories ?? []) {
    instance = this;

    // ugly... we need a type descriptor

    TypeDescriptor<Map<String, dynamic>>(
        location: "json" ,
        annotations: [],
        fromArrayConstructor: (List<dynamic> args) => HashMap<String,dynamic>(),
        fromMapConstructor: (Map<String,dynamic> args) => HashMap<String,dynamic>(),
        constructor: ()=>HashMap<String,dynamic>(),
        constructorParameters: [],
        fields: []
    );
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
  static T deserialize<T>(Map<String,dynamic> json) {
    return JSON.instance.getMapper(T).deserialize<T>(json);
  }
}