
import 'package:velix/util/collections.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/util/transformer.dart';
import 'mapper.dart';
/// @internal
abstract class MapperProperty extends Property<MappingContext> {
  Type getType();

  void validate(dynamic value){}
}

/// @internal
class MapList2List extends MapperProperty {
  // instance data

  final Type sourceType;
  final Type targetType;
  final MapperProperty property;
  final Function factory;
  final Mapper mapper;
  Mapping? mapping;

  // constructor

  MapList2List({required this.mapper, required this.sourceType, required this.targetType, required this.property, required this.factory}) {
    //mapping = mapper.getMappingX(sourceType, targetType);
  }

  // override

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    if (value != null) {
      var list = value as List;
      var len = list.length;
      var result = factory();

      var m = mapping ?? (mapping = mapper.getMappingX(sourceType, targetType)); // TODO...

      for (var i = 0; i < len; i++) {
        result.add(mapper.map(list[i], context: context, mapping: m));
      }

      property.set(instance, result, context);
    } // if
  }

  @override
  dynamic get(dynamic instance, MappingContext context) {
    return null;
  }

 @override
 Type getType() {
  return property.getType();
  }
}

/// @internal
class MapDeep extends MapperProperty {
  // instance data

  final Type sourceType;
  final MapperProperty targetProperty;
  final Mapper mapper;
  Mapping? mapping;

  // constructor

  MapDeep({required this.mapper, required this.sourceType, required this.targetProperty}) {
    //mapping = mapper.getMappingX(sourceType, targetProperty.getType());
  }


  // override AccessorValue

  @override
  dynamic get(dynamic instance, MappingContext context) {
    return null;
  }

  @override
  void set(dynamic instance,dynamic  value, MappingContext context) {
    var m = mapping ?? (mapping = mapper.getMappingX(sourceType, targetProperty.getType())); // TODO
    targetProperty.set(instance, mapper.map(value, context: context, mapping: m), context); // recursive call!
  }

  @override
  Type getType()  {
    return targetProperty.getType();
  }
}

/// @internal
class ConvertProperty extends MapperProperty {
  // instance data

  final MapperProperty property;
  final Converter conversion;

  // constructor

  ConvertProperty({required this.property, required this.conversion});

  // implement Property

  @override
  dynamic get(dynamic instance, MappingContext context) {
    return conversion(property.get(instance, context));
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    property.set(instance, conversion(value), context);
  }

  // implement

  @override
  Type getType()  {
    var type = Object;// TODO conversion.reflect()!!.returnType.jvmErasure

    return type;
  }
}

/// @internal
class SetResultArgument extends MapperProperty {
  // instance data

  final IntermediateResultDefinition  resultDefinition;
  final int index;
  final MapperProperty property;

  // constructor

  SetResultArgument({required this.resultDefinition, required this.index, required this.property}) {
    resultDefinition.missing -= 1;
  }

  // implement Property

  @override
  dynamic get(dynamic instance,  MappingContext context){
    throw MapperException("wrong direction");
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    property.validate(value); // hmm...maybe we can optimize that

    context.getResultBuffer(resultDefinition.index).set(instance, value, property, index, context);
  }

  @override
  Type getType() {
    if ( index < resultDefinition.constructorArgs)
      return resultDefinition.typeDescriptor.constructorParameters[index].type;
    else
      return property.getType();
  }
}

/// @internal
class PeekValueProperty extends MapperProperty {
  // instance data

  final int index;
  final MapperProperty property;

  // constructor

  PeekValueProperty({required this.index, required this.property});

  // implement Property

  @override
  dynamic get(dynamic instance, MappingContext context) {
    var value = context.peek(index);

    if (value != null) {
      return property.get(value, context);
    }
    else {
      return null;
    }
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    //throw IllegalArgumentException("not possible")
  }

  @override
  Type getType() {
    return property.getType();
  }
}

/// @internal
class PushValueProperty extends MapperProperty {
  // instance data

  final int index;

  // constructor

  PushValueProperty({required this.index});

  // implement Property

  @override
  dynamic get(dynamic instance, MappingContext context) {
    //throw java.lang.IllegalArgumentException("not possible")
  }

  @override
  void set(dynamic instance, dynamic value, MappingContext context) {
    context.push(value, index);
  }

  // implement MapperProperty

  @override
  Type getType() {
    return Object;
  }
}

/// @internal
abstract class ValueReceiver {
  void receive(MappingContext context, dynamic instance, dynamic value);
}

/// @internal
class SetPropertyValueReceiver extends ValueReceiver {
  // instance data

  final Property<MappingContext> property;

  // constructor

  SetPropertyValueReceiver({required this.property});

  // implement ValueReceiver

  @override
  void receive(MappingContext context, dynamic instance, dynamic value) {
    property.set(instance, value, context);
  }
}

/// @internal
class SetResultPropertyValueReceiver extends ValueReceiver {
  // instance data

  final int resultIndex;
  final int index;
  final Property<MappingContext>? property;

  // constructor

  SetResultPropertyValueReceiver({required this.resultIndex, required this.index, required this.property});

  // implement ValueReceiver

  @override
  void receive(MappingContext context, dynamic instance, dynamic value) {
    context.getResultBuffer(resultIndex).set(instance, value, property, index, context);
  }
}

class MappingResultValueReceiver extends ValueReceiver {
  // implement ValueReceiver

  @override
  void receive(MappingContext context, dynamic instance, dynamic value) {
    context.currentState?.result = value;
  }
}

/// @internal
class SourceNode {
  // instance data

  SourceNode? parent;
  Accessor accessor;
  Match? match;
  List<SourceNode> children = [];
  int stackIndex = -1; // this will hold the index in the stack of intermediate results

  Property<MappingContext>? fetchProperty; // the transformer property needed to fetch the value
  Type type;

  bool get isRoot { return parent == null; }

  bool get isLeaf {return children.isEmpty; }

  // constructor

  SourceNode({required this.accessor, required this.match, this.parent}) :  type = accessor.type;
  // public

  void fetchValue(SourceTree sourceTree, Type expectedType, List<Operation<MappingContext>> operations) {
    // recursion

    if (!isRoot) {
      parent!.fetchValue(sourceTree, expectedType, operations);
    }

    // fetch a stored value

    if (fetchProperty == null) {
      // root, no children...

      if (isRoot) {
        fetchProperty = accessor.makeTransformerProperty(false /* write */);
        type = accessor.type;
      }
      else {
        // inner node or leaf

        fetchProperty = PeekValueProperty(
            index: parent!.stackIndex,
            property: accessor.makeTransformerProperty(false /* read */)
        );
        type = accessor.type;
      }

      // in case of inner nodes take the result and remember it

      if (!isLeaf) {
        // store the intermediate result
        stackIndex = sourceTree.stackSize++; // that's my index
        operations.add(Operation(fetchProperty!, PushValueProperty(index: stackIndex)));
      } // if
    }
  }

  void insertMatch(SourceTree tree, Match match, int index) {
    SourceNode? root = findElement(children, (child) => child.accessor == match.paths[0][index]);

    if (root == null) {
      children.add(root = tree.makeNode(
        this,
          match.paths[0][index],  // step
        match.paths[0].length - 1 == index ? match : null));
    }

    if (match.paths[0].length > index + 1) {
      root.insertMatch(tree, match, index + 1);
    }
  }

  // pre: this node matches index - 1

  SourceNode? findMatchingNode(Match match, int index) {
    if (index < match.paths[0].length) {
      for (var child in children) {
        if (child.accessor == match.paths[0][index]) {
          return child.findMatchingNode(match, index + 1);
        }
      } // for
    } // if

    return this;
  }
}

/// @internal
class SourceTree {
  // instance data

  List<SourceNode> roots = [];
  int stackSize = 0;
  late Type type;

  // constructor

  SourceTree(this.type, List<Match> matches) {
    for ( var match in matches) {
      insertMatch(match);
    }
  }

  // public

  void insertMatch(Match match) {
    SourceNode? root = findElement(roots, (node) => node.accessor == match.paths[0][0]);

    if (root == null) {
      root = makeNode(null, // parent
          match.paths[0][0], // step
          match.paths[0].length == 1 ? match : null);

      roots.add(root);
    }

    if (match.paths[0].length > 1) {
      root.insertMatch(this, match, 1);
    }
  }

  SourceNode? findNode(Match match) {
    for (var node in roots) {
      if (node.match == match) {
        return node;
      }
      else if (node.accessor == match.paths[0][0])
        return node.findMatchingNode(match, 1);
    }

    return null; // make the compiler happy
  }

  SourceNode makeNode(SourceNode? parent, Accessor step, Match? match) {
    step.resolve(parent?.accessor.type ?? type, false);

    return SourceNode(accessor: step, parent: parent, match: match);
  }
}

/// @internal
class Buffer {
  // instance data

  final IntermediateResultDefinition definition;
  int nArgs;
  int constructorArgs;

  final FromArrayConstructor constructor;
  final ValueReceiver valueReceiver;

  int nSuppliedArgs = 0;
  //final Map<String,dynamic> arguments = {};
  final List<dynamic> arrayArguments;
  dynamic result;

 // constructor

  Buffer({required this.definition, required this.nArgs, required this.constructorArgs}) : arrayArguments = List<dynamic>.filled(constructorArgs, null), constructor = definition.constructor, valueReceiver = definition.valueReceiver {
    if ( constructorArgs == 0) {
      result = constructor([]);
    }
  }

  // public

  void set(dynamic instance, dynamic value, Property<MappingContext>? property, int index, MappingContext mappingContext) {
    // are we done?

    if (nSuppliedArgs < constructorArgs) {
      // create instance

      //arguments[param] = value;
      arrayArguments[index] = value;

      if ( nSuppliedArgs == constructorArgs - 1) {
        result = constructor(arrayArguments);
      }
    } // if
    else {
      property!.set(result!, value, mappingContext);
    }

    if ( ++nSuppliedArgs == nArgs) {
      valueReceiver.receive(mappingContext, instance, result!);
    }
  }
}

/// @internal
class IntermediateResultDefinition {
  // instance data

  final TypeDescriptor typeDescriptor;
  final FromArrayConstructor constructor;
  int index;
  int nArgs;
  final ValueReceiver valueReceiver;
  final int constructorArgs;

  int missing = 0;

  // constructor

  IntermediateResultDefinition({required this.typeDescriptor, required this.constructor, required this.index, required this.nArgs, required this.valueReceiver})
  : constructorArgs = typeDescriptor.constructorParameters.length {
    missing = constructorArgs;
  }

  // public

  Buffer createBuffer() {
    return Buffer(definition: this, nArgs: nArgs, constructorArgs: constructorArgs);
  }
}

/// @internal
class TargetNode {
  // instance data

  TargetNode? parent;
  Accessor accessor;
  Match? match;
  List<TargetNode> children = [];
  int stackIndex = -1; // this will hold the index in the stack of intermediate results
  IntermediateResultDefinition? resultDefinition;

  Property<MappingContext>? fetchProperty; // the transformer property needed to fetch the value
  late Type type;

  bool get isRoot {return parent == null; }

  bool get isLeaf {return children.isEmpty;}

  bool get isInnerNode {return children.isNotEmpty;}

  // constructor

  TargetNode({required this.accessor, required this.match, this.parent}) {
    type = accessor.type;
  }

  // public

  ValueReceiver computeValueReceiver() {
    if (parent?.resultDefinition != null) {
      parent?.resultDefinition!.missing -= 1;

      return SetResultPropertyValueReceiver(
          resultIndex: parent!.resultDefinition!.index,
          index: accessor.index,
          property: accessor.index >= parent!.resultDefinition!.constructorArgs ? accessor.makeTransformerProperty(true) : null
    );

    }
    else {
      return SetPropertyValueReceiver(property: accessor.makeTransformerProperty(true));
    }
  }

  Converter tryConvert(Type sourceType, Type targetType) {
    var conversion = Mapper.typeConversions.getConverter(sourceType, targetType);

    if ( conversion != null)
      return conversion;
    else
      throw MapperException("cannot convert $sourceType to $targetType");
  }

  Converter? calculateConversion(SourceNode sourceNode) {
    var conversion = match!.converter;
    var deep = match!.deep;

    Converter<dynamic,dynamic>? result;

    // check conversion

    var sourceType = sourceNode.accessor.type;
    var targetType = accessor.type;

    if ( conversion != null) {
      // manual conversion, check types!

      var from = conversion.sourceType;
      var to = conversion.targetType;

      if ( from != sourceType)
        throw MapperException("conversion source type $from does not match $sourceType");

      if ( to != targetType)
        throw MapperException("conversion target type $to does not match $targetType");

      result = conversion.get();
    }
    else if (sourceType != targetType && /* !sourceType.isSubclassOf(targetType)*/ !deep )
      result = tryConvert(sourceType, targetType); // try automatic conversion for low-level types

    return result;
  }

  MapperProperty maybeConvert(MapperProperty property, Converter? conversion){
    if (conversion == null)
      return property;
    else {
      return ConvertProperty(property: property, conversion: conversion);
    }
  }

  MapperProperty mapDeep(Mapper mapper, Accessor source, Accessor target, MapperProperty targetProperty) {
    var isSourceMultiValued = source.isContainer();
    var isTargetMultiValued = target.isContainer();

    if (isSourceMultiValued != isTargetMultiValued)
      throw MapperException("relations must have the same cardinality");

    if (isSourceMultiValued) {
      return MapList2List(
          mapper: mapper,
          sourceType: source.getElementType(),
          targetType:  target.getElementType(),
          property: targetProperty,
          factory: target.getContainerConstructor()!);
    }
    else {
      return MapDeep(mapper: mapper, sourceType: source.type, targetProperty: targetProperty);
    }
  }

  Operation<MappingContext> makeOperation(SourceNode sourceNode, Mapper mapper) {
    var sourceProperty = sourceNode.fetchProperty!;

    var deep = match!.deep;
    var conversion = calculateConversion(sourceNode);

    // compute operation

    var requiresWrite = parent!.resultDefinition == null;

    var writeProperty = accessor.makeTransformerProperty(requiresWrite) ;// property, constant or synchronizer

    if (parent!.resultDefinition != null) {
      parent!.resultDefinition!.missing -= 1;

      writeProperty = SetResultArgument(
        resultDefinition: parent!.resultDefinition!,
        index: accessor.index,
        property: writeProperty
      );
    }

    if ( deep )
      writeProperty = mapDeep(mapper, sourceNode.accessor, accessor, writeProperty);
    else
      writeProperty = maybeConvert(writeProperty, conversion);

    return Operation(sourceProperty, writeProperty);
  }

  void makeOperations(SourceTree sourceTree, TargetTree targetTree, Mapper mapper, MappingDefinition definition, List<Operation<MappingContext>> operations) {
    var type = accessor.type;

    if ( isRoot ) {
      var descriptor = TypeDescriptor.forType(targetTree.type);

      if (descriptor.isImmutable() || !descriptor.hasDefaultConstructor()) {
        resultDefinition = definition.addIntermediateResultDefinition(TypeDescriptor.forType(type), descriptor.fromArrayConstructor!, children.length, MappingResultValueReceiver());
      }

      // recursion

      for (var child in children) {
        child.makeOperations(sourceTree, targetTree, mapper, definition, operations);
      }
    } // if
    else if (isInnerNode) {
      var descriptor = TypeDescriptor.forType(type);

      var valueReceiver = computeValueReceiver();

      var constructor = descriptor.fromArrayConstructor;

      // done

      resultDefinition = definition.addIntermediateResultDefinition(descriptor, constructor!, children.length, valueReceiver);

      // recursion

      for (var child in children) {
        child.makeOperations(sourceTree, targetTree, mapper, definition, operations);
      }
    } // if

    else { // leaf
      var sourceNode = sourceTree.findNode(match!)!;

      sourceNode.fetchValue(sourceTree, type, operations); // compute property needed to fetch source value

      operations.add(makeOperation(sourceNode, mapper));
    } // if
  }

  void insertMatch(TargetTree tree, Match match, int index) {
    TargetNode? root = findElement(children, (child) => child.accessor == match.paths[1][index]);

    if (root == null) {
      children.add(root = tree.makeNode(
          this,
          match.paths[1][index],  // step
          match.paths[1].length - 1 == index ? match : null
      ));
    }

    if (match.paths[1].length > index + 1) {
      root.insertMatch(tree, match, index + 1);
    }
  }

  // pre: this node matches index - 1

  TargetNode? findMatchingNode(Match match, int index) {
    if (index < match.paths[0].length) {
      for (var child in children) {
        if (child.accessor == match.paths[0][index]) {
          return child.findMatchingNode(match, index + 1);
      }
        }
    } // if

    return this;
  }
}

/// @internal
class RootAccessor extends Accessor {
  // constructor

  RootAccessor(Type type) : super(name: "", type: type, index: 0, readOnly: false);

  @override
  MapperProperty makeTransformerProperty(bool write) {
    throw UnimplementedError();
  }

  @override
  void resolve(Type type, bool write) {
  }

  // override Object

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return false;
  }

  @override
  int get hashCode => 1;
}

/// @internal
class TargetTree {
  // instance data

  late TargetNode root;
  int stackSize = 0;
  late Type type;

  // constructor

  TargetTree(this.type, List<Match> matches) {
    root = TargetNode(accessor: RootAccessor(type), parent: null, match: null);

    for ( var match in matches) {
      root.insertMatch(this, match, 0);
    }
  }

  // public

  List<Operation<MappingContext>>  makeOperations(SourceTree sourceTree, Mapper mapper, MappingDefinition definition) {
    List<Operation<MappingContext>> operations = [];

    // traverse recursively

    root.makeOperations(sourceTree, this, mapper, definition, operations);

    return operations;
  }

  TargetNode makeNode(TargetNode? parent, Accessor step, Match? match) {
    step.resolve(parent?.accessor.type ?? type, false);

    return TargetNode(accessor: step, parent: parent, match: match);
  }
}

/// @internal
class OperationResult {
  // instance data

  List<Operation<MappingContext>> operations;
  Function constructor;
  int stackSize;

  // constructor

  OperationResult({required this.operations, required this.constructor, required this.stackSize});
}

/// @internal
class OperationBuilder {
  // instance data

  List<Match> matches;

  // constructor

  OperationBuilder({required this.matches});

  // public

  OperationResult makeOperations(Mapper mapper, MappingDefinition definition)  {
    var sourceTree = SourceTree(definition.sourceClass, matches);
    var targetTree = TargetTree(definition.targetClass, matches);

    var operations = targetTree.makeOperations(sourceTree, mapper, definition);
    Function constructor;
    if ( targetTree.root.resultDefinition != null ) {
      constructor = targetTree.root.resultDefinition!.constructor;
    }
    else {
      constructor = TypeDescriptor.forType(definition.targetClass).constructor!; // hmmm
    }

    return OperationResult(operations: operations, constructor: constructor, stackSize: sourceTree.stackSize);
  }
}
