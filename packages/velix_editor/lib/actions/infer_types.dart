

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/actions/visitor.dart';

import 'autocomplete.dart';
import 'expressions.dart';

// we need a generalized mechanism, since we have to deal with real types ( e.g. TypeDescriptor )
// as well as the information available from json files with no representation in the runtime. Gosh...

class TypeInfo<T> {
  final T type;

  TypeInfo(this.type);

  V getType<V>() => type as V;
}

abstract class TypeResolver<T> {
  T resolve(String name, {T? parent});

  T resolveType(Type type);

  T rootType();

  bool isAssignableFrom(T a, T b);
}

// this is the implementation for real types

class RuntimeTypeInfo extends TypeInfo<AbstractType> {
  RuntimeTypeInfo(super.type);
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
  RuntimeTypeInfo rootType() {
    return RuntimeTypeInfo(root.objectType);
  }

  @override
  RuntimeTypeInfo resolve(String name, {RuntimeTypeInfo? parent}) {
    if ( parent == null)
      return RuntimeTypeInfo(root.getProperty(name).type);
    else
      return RuntimeTypeInfo((parent.type as ObjectType).typeDescriptor.getProperty(name).type);
  }

  @override
  RuntimeTypeInfo resolveType(Type type) {
    return RuntimeTypeInfo(getTypeFor(type));
  }

  @override
  bool isAssignableFrom(RuntimeTypeInfo a, RuntimeTypeInfo b) {
    return a.type.type == b.type.type; // TODO
  }
}

// TODO

class ClassDescTypeInfo extends TypeInfo<Desc> {
  // constructor

  ClassDescTypeInfo(super.type);
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

  // constructor

  ClassDescTypeResolver({required ClassDesc root}): root = ClassDescTypeInfo(root);

  // internal

  // override

  @override
  ClassDescTypeInfo resolve(String name, {ClassDescTypeInfo? parent}) {
    var parentType = (parent ?? root).type;

    if ( parentType is ClassDesc)
      return ClassDescTypeInfo(parentType.find(name)?.type ?? UnknownPropertyDesc(parent: parentType, property: name));
    else
      return ClassDescTypeInfo(UnknownPropertyDesc(parent: parentType, property: name));
  }

  @override
  ClassDescTypeInfo resolveType(Type type) { // who calls that?
    throw ClassDescTypeInfo(Desc.dynamic_type); // TODO
  }

  @override
  ClassDescTypeInfo rootType() {
    return root;
  }

  @override
  bool isAssignableFrom(ClassDescTypeInfo a, ClassDescTypeInfo b) {
    return a.type.name == b.type.name; // TODO
  }
}


class TypeChecker implements ExpressionVisitor<TypeInfo> {
  // instance data

  final TypeResolver resolver;

  // constructor

  TypeChecker(this.resolver);

  // override

  @override
  TypeInfo visitLiteral(Literal expr) {
    return expr.type = resolver.resolveType(expr.value.runtimeType);
  }

  @override
  TypeInfo visitIdentifier(Identifier expr) => expr.type = resolver.resolveType(String);

  @override
  TypeInfo visitVariable(Variable expr) {
    return expr.type = resolver.resolve(expr.identifier.name);
  }

  @override
  TypeInfo visitUnary(UnaryExpression expr) {
    expr.argument.accept(this);

    return resolver.resolveType(int); // TODO
  }

  @override
  TypeInfo visitBinary(BinaryExpression expr) {
    expr.left.accept(this);
    expr.right.accept(this);

    return resolver.resolveType(int); // TODO
  }

  @override
  TypeInfo visitConditional(ConditionalExpression expr) {
    expr.test.accept(this);
    expr.consequent.accept(this);
    expr.alternate.accept(this);

    return resolver.resolveType(bool); // TODO
  }

  @override
  TypeInfo visitMember(MemberExpression expr) {
    var objType = expr.object.accept(this);

    return expr.type = resolver.resolve(expr.property.name, parent: objType);
  }

  @override
  TypeInfo visitIndex(IndexExpression expr) {
    expr.object.accept(this);
    expr.index.accept(this);

    return resolver.resolveType(int); // TODO
  }

  @override
  TypeInfo visitCall(CallExpression expr) { // callee, arguments
    expr.callee.accept(this);

    // resolve arguments

    for ( var argument in expr.arguments)
      argument.accept(this);

    if (expr.callee is Variable) {
      expr.type = resolver.resolve((expr.callee as Variable).identifier.name);
    }

    else if (expr.callee is MemberExpression) {
      final member = expr.callee as MemberExpression;
      final objType = member.object.type;

      if (objType != null) {
        // TODO we need to check if the arguments are ok, both number and type!
        expr.type = resolver.resolve(member.property.name, parent: objType);
      }
    }

    return expr.type!;
  }

  @override
  TypeInfo visitThis(ThisExpression expr) => expr.type = resolver.rootType();
}