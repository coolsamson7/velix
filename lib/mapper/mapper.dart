import 'dart:collection';

import 'operation_builder.dart';
import 'transformer.dart';
import '../reflectable/reflectable.dart';

typedef Converter<S,T> = T Function(S);

class Convert<S, T> {
  final Converter<S, T> convert;

  Convert(this.convert);

  Converter<dynamic, dynamic> get() {
    return (dynamic s) => convert(s);
  }

  Type get sourceType => S;
  Type get targetType => T;
}

typedef Finalizer<S, T> = void Function(S,T);

class TypeKey {
  // instance data

  final Type from;
  final Type to;

  // constructor

  const TypeKey(this.from, this.to);

  // override

  @override
  bool operator ==(Object other) =>
      other is TypeKey && other.from == from && other.to == to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;

  @override
  String toString() => '$from -> $to';
}

class TypeConversionTable {
  static final Map<TypeKey, Converter> _converters = {
    TypeKey(String, int):    (v) => int.tryParse(v),
    TypeKey(String, double): (v) => double.tryParse(v),
    TypeKey(String, bool):   (v) => v.toLowerCase() == 'true',
    TypeKey(String, DateTime): (v) => DateTime.tryParse(v),

    TypeKey(bool, int):    (v) => v ? 1 : 0,
    TypeKey(bool, double): (v) => v ? 1.0 : 0.0,

    TypeKey(int, String):    (v) => v.toString(),
    TypeKey(double, String):    (v) => v.toString(),

    TypeKey(int, double):    (v) => v.toDouble(),
    TypeKey(double, int):    (v) => v.toInt(),

    TypeKey(int, bool):    (v) => v == 1 ? true : false,
    TypeKey(double, bool):    (v) => v == 1.0 ? true : false,
  };

  static Converter? getConverter(Type fromType, Type toType) {
    final key = TypeKey(fromType, toType);

    return _converters[key];
  }

  static dynamic convert(dynamic value, Type fromType, Type toType) {
    if (value == null || fromType == toType) return value;

    final key = TypeKey(fromType, toType);
    final converter = _converters[key];

    if (converter != null) return converter(value);

    // fallback if exact runtime types match
    if (value.runtimeType == toType) return value;

    throw UnsupportedError('No converter registered for $fromType -> $toType');
  }

  static void register<S, T>(Converter converter) {
    _converters[TypeKey(S, T)] = converter;
  }
}

List<String> path(String a, [String? b, String? c, String? d, String? e, String? f, String? g, String? h]) {
  return [a, b, c, d, e, f, g, h].whereType<String>().toList();
}

class PropertyProperty extends MapperProperty {
  // instance data

  final FieldDescriptor field;

  // constructor

  PropertyProperty({required this.field});

  // override

  @override
  dynamic get(dynamic instance, MappingContext context) {
    return field.getter(instance);
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    field.setter!(instance, value);
  }

  // override

  @override
  Type getType() {
    return field.type.type;
  }
}

abstract class Accessor {
  // instance data

  String name;
  int index;
  bool readOnly;
  Type type;

  // constructor

  Accessor({required this.name, required this.type, required this.index, this.readOnly = false });

  // abstract

  void resolve(Type type, bool write);

  MapperProperty makeTransformerProperty(bool write);
}

class MapperException implements Exception  {
  final String message;

  MapperException(this.message);

  @override
  String toString() => 'MapperException: $message';

}

class ConstantValue extends MapperProperty {
  // instance data

  final dynamic value;

  // constructor

  ConstantValue({required this.value});

  // implement

  @override
  dynamic get(dynamic instance, MappingContext context) {
    return value;
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
  }

  @override
  Type getType() {
    return value.runtimeType;
  }
}

class ConstantAccessor extends Accessor {
  // instance data

  dynamic value;

  // constructor

  ConstantAccessor({required this.value}) : super(name: value.toString(), readOnly: true, index: 0, type: value.runtimeType);

  // override
  @override
  void resolve(Type type, bool write) {
    if ( write )
      throw MapperException("constants are not writeable");
  }

  @override
  MapperProperty makeTransformerProperty(bool write) {
  if ( write )
    throw MapperException("constants are not writeable");
  else
    return ConstantValue(value: value);
  }

  // override Object

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return false;
  }

  @override
  int get hashCode => value != null ? value.hashCode : 0;
}

class PropertyAccessor extends Accessor {
  // instance data

  late FieldDescriptor field;

  // constructor

  PropertyAccessor({required String name })
      : super(name: name, type: Object, index: -1, readOnly: false);

  // override

  @override
  MapperProperty makeTransformerProperty(bool write) {
    if ( write ) {
      if ( field.isWriteable()) {
        return PropertyProperty(field: field);
      }
      else {
        throw MapperException("${field.typeDescriptor.type}.$name is final");
      }
    }
    else {
      return PropertyProperty(field: field);
    }
  }

  @override
  void resolve(Type type, bool write) {
    var descriptor = TypeDescriptor.forType(type);

    index = descriptor.constructorParameters.indexWhere((param) => param.name == name);

    field = descriptor.getField(name);
    super.type = field.type.type;
  }

  // override Object

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    PropertyAccessor propertyAccessor = other as PropertyAccessor;

    return name == propertyAccessor.name;
  }

  @override
  int get hashCode => name.hashCode;
}

class Mapping<S,T> extends Transformer<MappingContext> {
  // instance data

  Mapper mapper;
  MappingDefinition<S,T> definition;
  TypeDescriptor typeDescriptor;
  Function constructor;
  int stackSize;
  List<IntermediateResultDefinition>  intermediateResultDefinitions;
  List<Finalizer<dynamic,dynamic>> finalizer;

  // constructor

  Mapping({required this.mapper, required this.typeDescriptor, required this.constructor, required this.stackSize, required this.intermediateResultDefinitions, required this.definition, required List<Operation<MappingContext>> operations, required this.finalizer})
      :super(operations);

  // public

  MappingState setupContext(MappingContext context)  {
    var state = MappingState(context: context);

    context.setup(intermediateResultDefinitions, stackSize);

    return state;
  }

  dynamic newInstance() {
    return constructor.call();
  }
}

abstract class MapOperation {
  // instance data

  bool deep;
  Convert? converter;

  // constructor

  MapOperation({this.converter, this.deep = false});

  // abstract

  void findMatches(MappingDefinition definition,List<Match> matches);
}

 abstract class PropertyQualifier {
  List<String> computeProperties(Type sourceClass, Type targetClass);
 }

class Properties extends PropertyQualifier {
  // instance data

  final List<String> properties;

  // constructor

  Properties({required this.properties});

  // implement

  @override
  List<String> computeProperties(Type sourceClass, Type targetClass) {
    return properties;
  }
}

class AllProperties extends PropertyQualifier {
  // instance data

  List<String> exceptions = [];

  // constructor

  AllProperties();

  // public

  AllProperties except(List<String> properties) {
    for ( var property in properties)
      exceptions.add(property);

    return this;
  }

  // implement

  @override
  List<String> computeProperties(Type sourceClass, Type targetClass) {
    List<String> result = [];

    var sourceDescriptor = TypeDescriptor.forType(sourceClass);
    var targetDescriptor = TypeDescriptor.forType(targetClass);

    var names = sourceDescriptor.getFieldNames();

    for (var property in names) {
      if (exceptions.contains(property))
        continue;

      if (sourceDescriptor.hasField(property) && targetDescriptor.hasField(property))
        result.add(property);
    } // for

    return result;
  }
}

Properties properties(List<String> properties) {
  return Properties(properties: properties);
}

AllProperties matchingProperties() {
  return AllProperties();
}

class Match {
  // instance data

  final List<Accessor> source ;
  final List<Accessor> target ;
  final MapOperation operation;
  late List<List<Accessor>> paths;

  bool get deep { return operation.deep; }

  Convert? get converter { return operation.converter; }

  // constructor

  Match({required this.operation, required this.source, required this.target}) {
    paths = [source, target];
  }
}

class MapProperties extends MapOperation {
  // instance data

  final PropertyQualifier qualifier;

  // constructor

  MapProperties({required this.qualifier, Convert? converter, deep = false}) : super(deep: deep, converter: converter);

  // internal

  List<String> computeProperties(Type sourceClass, Type targetClass) {
    return qualifier.computeProperties(sourceClass, targetClass);
  }

  // override

  @override
  void findMatches(MappingDefinition definition, List<Match> matches) {
    for (var property in computeProperties(definition.sourceClass, definition.targetClass))
      matches.add(Match(
          operation: this,
          source: [PropertyAccessor(name: property)],
          target: [PropertyAccessor(name: property)]
      ));
  }
}

class MapAccessor extends MapOperation {
  // instance data

  final List<Accessor> source;
  final List<Accessor> target;

  // constructor

  MapAccessor({required this.source, required this.target, Convert? converter, bool deep = false}) : super(deep: deep, converter: converter);

  // override

  @override
  void findMatches(MappingDefinition definition,List<Match> matches) {
    matches.add(Match(operation: this, source: source, target: target));
  }
}


class MappingDefinition<S,T> {
  // instance data

  late Type sourceClass;
  late Type targetClass;

  List<MapOperation> operations = [];
  List<IntermediateResultDefinition> intermediateResultDefinitions = [];
  Finalizer<dynamic,dynamic>? finalizer;
  MappingDefinition<S,T>? baseMapping;

  // constructor

  MappingDefinition() {
    this.sourceClass = S;
    this.targetClass = T;
  }

  // internal

  IntermediateResultDefinition addIntermediateResultDefinition(Type clazz, Function ctr, int nargs, ValueReceiver valueReceiver) {
    intermediateResultDefinitions.add(IntermediateResultDefinition (clazz: clazz, constructor:  ctr, index: intermediateResultDefinitions.length, nArgs: nargs, valueReceiver: valueReceiver));

    return intermediateResultDefinitions.last;
  }

  List<Finalizer<dynamic,dynamic>> collectFinalizer()  {
    List<Finalizer<dynamic,dynamic>> finalizer = [];

    // local function

    void collect(MappingDefinition<S,T> definition) {
      if ( definition.baseMapping != null )
        collect(definition.baseMapping!);

        if ( definition.finalizer != null)
          finalizer.add(definition.finalizer!);
    }

  // go, forrest

  collect(this);

  // done

  return finalizer;
  }

  void findMatches(List<Match> matches) {
    // recursion

    if (baseMapping != null)
      baseMapping!.findMatches(matches);

    // own matches

    for (var operation in operations) {
      operation.findMatches(this, matches);
    }
  }

  OperationResult createOperations(Mapper mapper)  {
    List<Match> matches = [];

    findMatches(matches);

    return OperationBuilder(matches: matches).makeOperations(mapper, this);
  }

  Mapping<S,T> createMapping(Mapper mapper) {
    var result = createOperations(mapper);

    return Mapping<S,T>(
        mapper: mapper,
        definition: this,
        operations: result.operations,
        typeDescriptor: TypeDescriptor.forType(targetClass),
        constructor: result.constructor,
        stackSize: result.stackSize,
        intermediateResultDefinitions: intermediateResultDefinitions,
        finalizer: collectFinalizer());
  }

  // fluent

  MappingDefinition<S,T>  derives(MappingDefinition<S,T> mappingDefinition) {
    baseMapping = mappingDefinition;

    return this;
  }

  MappingDefinition<S,T>  map({dynamic constant, dynamic from, PropertyQualifier? all, dynamic to,  bool deep = false, Convert? convert}) {
    if ( all != null) {
      operations.add(MapProperties(qualifier: all, converter: convert, deep: deep));
    }
    else {
      List<Accessor> fromAccessors = [];
      List<Accessor> toAccessors = [];

      if ( from is String)
        fromAccessors.add(PropertyAccessor(name: from));

      else if (from is List<String>)
        fromAccessors = (from).map((element) => PropertyAccessor(name: element)).toList(growable: false);

      if ( constant != null)
        fromAccessors.add(ConstantAccessor(value: constant));

      if ( to is String)
        toAccessors.add(PropertyAccessor(name: to));

      if (to is List<String>)
        toAccessors = (to).map((element) => PropertyAccessor(name: element)).toList(growable: false);

      // done

      operations.add(MapAccessor(
          source: fromAccessors,
          target: toAccessors,
          deep: deep,
          converter: convert
      ));
    }

    return this;
  }

  MappingDefinition<S,T> finalize(Finalizer<S,T> finalizer)  {
    this.finalizer = (dynamic source, dynamic target) => finalizer(source, target);

    return this;
  }
}

MappingDefinition<S,T> mapping<S,T>() {
  return MappingDefinition<S,T>();
}

class MappingState {
  // instance data

  MappingContext context;
  late List<Buffer> resultBuffers;
  late List<dynamic> stack;
  dynamic result;
  late MappingState? nextState;

  // constructor

  MappingState({required this.context}) {
    nextState = context.currentState;

    context.currentState = this;
    resultBuffers = context.resultBuffers;
    stack = context.stack;
  }

  // public

  void restore(MappingContext context) {
    context.resultBuffers = resultBuffers;
    context.stack = stack;
    context.currentState = nextState;
  }
}

class MappingContext {
  // instance data

  Mapper mapper;
  dynamic currentSource;
  dynamic currentTarget;
  Map<dynamic, dynamic>  mappedObjects = Map.identity();
  List<Buffer> resultBuffers = [];
  List<dynamic> stack = [];
  MappingState? currentState;

  // constructor

  MappingContext({required this.mapper});

  // public

  MappingContext remember(dynamic source, dynamic target) {
    mappedObjects[source] = target;

    currentSource = source;
    currentTarget = target;

    return this;
  }

  dynamic mappedObject(dynamic source) {
    return mappedObjects[source];
  }

  List<Buffer> setupResultBuffers(List<Buffer> buffers) {
    var saved = resultBuffers;

    resultBuffers = buffers;

    return saved;
  }

  List<Buffer> setup(List<IntermediateResultDefinition> intermediateResultDefinitions, int stackSize) {
    List<Buffer> buffers = List.generate(intermediateResultDefinitions.length, (i) => intermediateResultDefinitions[i].createBuffer());

    if (stackSize > 0)
     stack = List.filled(stackSize, null);

    return setupResultBuffers(buffers);
  }

  Buffer getResultBuffer(int index) {
    return resultBuffers[index];
  }

   void push(dynamic value, int index) {
    stack[index] = value;
  }

  dynamic peek(int index) {
    return stack[index];
  }
}

class Mapper {
  // instance data

  late List<MappingDefinition> mappingDefinitions;
  Map<Type, Mapping> mappings = HashMap<Type,Mapping>();

  // constructor

  Mapper(List<MappingDefinition> definitions) {
    mappingDefinitions = definitions;

    for (var definition in mappingDefinitions) {
      registerMapping(definition.createMapping(this));
    }
  }

  // internal

  MappingContext createContext() {
    return MappingContext(mapper: this);
  }

  void registerMapping(Mapping mapping) {
    mappings[mapping.definition.sourceClass] = mapping;
  }

  Mapping<S,T> getMapping<S,T>(Type sourceClass) {
    return mappings[sourceClass] as Mapping<S,T>;
  }

  // public

  T? map<S,T>(S source, {MappingContext? context}) {
    if ( source == null)
      return null;

    Mapping<S,T> mapping = getMapping<S,T>(source.runtimeType);

    context ??= MappingContext(mapper: this);

    dynamic target = context.mappedObject(source);

    var lazyCreate = false;
    if ( target == null) {
      lazyCreate = mapping.typeDescriptor.isImmutable() || !mapping.typeDescriptor.hasDefaultConstructor();
      if (lazyCreate)
        target = context; // we need to set something....
      else {
        target = mapping.newInstance();

        context.remember(source, target);
      }
    }

    var state = mapping.setupContext(context);
    try {
      mapping.transformTarget(source, target, context);

      if ( lazyCreate ) {
        target =  context.currentState!.result;

        context.remember(source, target!!);
      }
    }
    finally {
      state.restore(context);
    }

    for (Function finalizer in mapping.finalizer)
      finalizer(source, target);

    return target as T;
  }
}