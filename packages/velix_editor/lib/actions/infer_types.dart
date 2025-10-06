

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/actions/visitor.dart';

import 'autocomplete.dart';
import 'expressions.dart';

// we need a generalized mechanism, since we have to deal with real types ( e.g. TypeDescriptor )
// as well as the information available from json files with no representation in the runtime. Gosh...

class TypeInfo<T,D> {
  final T type;
  final D? descriptor;

  TypeInfo(this.type, this.descriptor);

  V getType<V>() => type as V;
  V getDescriptor<V>() => descriptor as V;
}

class TypeException implements Exception {
  // instance data

  final String message;
  final Exception? cause;

  // constructor

  /// Create a new [ConfigurationException]
  /// [message] the message
  /// [cause] optional chained exception
  const TypeException(this.message, [this.cause]);

  // override

  @override
  String toString() => 'TypeException: $message';
}

abstract class TypeResolver<T extends TypeInfo<dynamic,dynamic>> {
  void checkArguments(dynamic descriptor, List<T> arguments);

  T resolve(String name, {T? parent});

  T resolveType(Type type);

  T rootType();

  bool isAssignableFrom(dynamic a, dynamic b);
}

// this is the implementation for real types

class RuntimeTypeInfo extends TypeInfo<AbstractType,AbstractDescriptor> {
  RuntimeTypeInfo(super.type, super.descriptor);
}

class RuntimeTypeTypeResolver extends TypeResolver<RuntimeTypeInfo> {
  // static data

  static Map<Type, AbstractType> types = {
    String: StringType(),
    int: IntType(),
    double: DoubleType(),
    bool: BoolType(),
  };

  static AbstractType getTypeFor(Type type) {
    return types[type]!; // TODO
  }

  // instance data

  TypeDescriptor root;

  // constructor

  RuntimeTypeTypeResolver({required this.root});

  // override

  @override
  void checkArguments(dynamic descriptor, List<TypeInfo> arguments) {
    var method = descriptor as MethodDescriptor;

    if (method.parameters.length != arguments.length)
      throw TypeException("${method.name} expects ${method.parameters.length} arguments");

    for (var i = 0; i <  arguments.length; i++) {
      if (!isAssignableFrom(descriptor.parameters[i].type, arguments[i].type.type))
        throw TypeException("${method.name} parameter $i ${descriptor.parameters[i].name} expected a ${descriptor.parameters[i].type.toString()} ");
    }
  }

  @override
  RuntimeTypeInfo rootType() {
    return RuntimeTypeInfo(root.objectType, null);
  }

  @override
  RuntimeTypeInfo resolve(String name, {RuntimeTypeInfo? parent}) {
    if ( parent == null)
      return RuntimeTypeInfo(root.getProperty(name).type, root.getProperty(name));
    else {
      var descriptor = parent.getType<ObjectType>().typeDescriptor.getProperty(name);
      return RuntimeTypeInfo(descriptor.type, descriptor);
    }
  }

  @override
  RuntimeTypeInfo resolveType(Type type) {
    return RuntimeTypeInfo(getTypeFor(type), null);
  }

  @override
  bool isAssignableFrom(dynamic a, dynamic b) {
    return a == b;
  }
}

// TODO

class ClassDescTypeInfo extends TypeInfo<Desc,Desc> {
  // constructor

  ClassDescTypeInfo(super.type, super.descriptor);
}

class UnknownPropertyDesc extends Desc {
  // instance

  Desc parent;
  String property;

  // constructor

  UnknownPropertyDesc({required this.parent, required this.property})
      : super('');

  // public

  Iterable<Suggestion> suggestions() {
    return parent is ClassDesc ? (parent as ClassDesc).properties.values
        .where((desc) => desc.name.startsWith(property))
        .map((prop) => Suggestion(
              suggestion: prop.name,
              type: prop.isField() ? "field" : "method",
              tooltip: "")) : [];
  }
}

class ClassDescTypeResolver extends TypeResolver<ClassDescTypeInfo> {
  // instance data

  ClassDescTypeInfo root;

  Map<String,Desc> types = {};

  Desc getType(String name) {
    var result = types[name];
    if ( result == null) {
      result = Desc.getType(name);
      types[name] = result;
    }

    return result;
  }

  // constructor

  ClassDescTypeResolver({required ClassDesc root}): root = ClassDescTypeInfo(root, null);

  // internal

  // override

  @override
  void checkArguments(dynamic descriptor, List<ClassDescTypeInfo> arguments) {
    var method = descriptor as MethodDesc;

    // number

    if (method.parameters.length != arguments.length)
      throw TypeException("${method.name} expects ${method.parameters.length} arguments");

    // type

    for (var i = 0; i <  arguments.length; i++) {
      if (!isAssignableFrom(descriptor.parameters[i].type, arguments[i].type))
        throw TypeException("${method.name} parameter $i ${descriptor.parameters[i].name} expected a ${descriptor.parameters[i].type.name} ");
    }
  }

  @override
  ClassDescTypeInfo resolve(String name, {ClassDescTypeInfo? parent}) {
    var parentType = (parent ?? root).type;

    if ( parentType is ClassDesc) {
      var property  = parentType.find(name);
      return ClassDescTypeInfo(property?.type ?? UnknownPropertyDesc(parent: parentType, property: name), property);
    }
    else
      return ClassDescTypeInfo(UnknownPropertyDesc(parent: parentType, property: name), null);
  }

  @override
  ClassDescTypeInfo resolveType(Type type) {
    return ClassDescTypeInfo(getType(type.toString()), null);
  }

  @override
  ClassDescTypeInfo rootType() {
    return root;
  }

  @override
  bool isAssignableFrom(dynamic a, dynamic b) {
    if ( b is UnknownPropertyDesc)
      return true;

    return a == b;
  }
}


class TypeChecker<TI extends TypeInfo> implements ExpressionVisitor<TI> {
  // instance data

  final TypeResolver<TI> resolver;

  // constructor

  TypeChecker(this.resolver);

  // override

  @override
  TI visitLiteral(Literal expr) {
    return expr.type = resolver.resolveType(expr.value.runtimeType);
  }

  @override
  TI visitIdentifier(Identifier expr) => expr.type = resolver.resolveType(String);

  @override
  TI visitVariable(Variable expr) {
    return expr.type = resolver.resolve(expr.identifier.name);
  }

  @override
  TI visitUnary(UnaryExpression expr) {
    expr.argument.accept(this);

    return resolver.resolveType(int); // TODO
  }

  @override
  TI visitBinary(BinaryExpression expr) {
    expr.left.accept(this);
    expr.right.accept(this);

    return resolver.resolveType(int); // TODO
  }

  @override
  TI visitConditional(ConditionalExpression expr) {
    expr.test.accept(this);
    expr.consequent.accept(this);
    expr.alternate.accept(this);

    return resolver.resolveType(bool); // TODO
  }

  @override
  TI visitMember(MemberExpression expr) {
    var objType = expr.object.accept(this);

    return expr.type = resolver.resolve(expr.property.name, parent: objType);
  }

  @override
  TI visitIndex(IndexExpression expr) {
    expr.object.accept(this);
    expr.index.accept(this);

    return resolver.resolveType(int); // TODO
  }

  @override
  TI visitCall(CallExpression expr) { // callee, arguments
    expr.callee.accept(this);

    // resolve arguments

    List<TI> argumentTypes = expr.arguments.map((arg) => arg.accept(this)).toList();

    if (expr.callee is Variable) {
      resolver.checkArguments(expr.getDescriptor(), argumentTypes);
      expr.type = resolver.resolve((expr.callee as Variable).identifier.name);
    }

    else if (expr.callee is MemberExpression) {
      final member = expr.callee as MemberExpression;
      TI? objType = member.object.type as TI?;

      resolver.checkArguments(member.getDescriptor(), argumentTypes);
      if (objType != null) {
        expr.type = resolver.resolve(member.property.name, parent: objType);
      }
    }

    return expr.type as TI;
  }

  @override
  TI visitThis(ThisExpression expr) => expr.type = resolver.rootType();
}