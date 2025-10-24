import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/actions/visitor.dart';

import 'autocomplete.dart';
import 'expressions.dart';

// we need a generalized mechanism, since we have to deal with real types ( e.g. TypeDescriptor )
// as well as the information available from json files with no representation in the runtime. Gosh...

abstract class TypeInfo<T,D> {
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

  T resolve(String name, {required Expression forExpression, T? parent});

  T resolveType(Type type);

  T rootType();

  bool isAssignableFrom(dynamic a, dynamic b);

  TypeCheckerContext makeContext();
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
  final Map<String,Type> variables;

  // constructor

  RuntimeTypeTypeResolver({required this.root, Map<String,Type>? variables}) : variables = variables ?? {};

  // override

  @override
  TypeCheckerContext makeContext() {
    return TypeCheckerContext<RuntimeTypeInfo>();
  }

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
  RuntimeTypeInfo resolve(String name, {required Expression forExpression, RuntimeTypeInfo? parent}) {
    if ( parent == null)
      if ( variables.containsKey(name))
        return RuntimeTypeInfo(ClassType(variables[name]!), null);
      else
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

class ClassDescTypeInfo extends TypeInfo<Desc,Desc> {
  // constructor

  ClassDescTypeInfo(super.type, super.descriptor);
}

class UnknownPropertyDesc extends Desc {
  // instance

  Desc parent;
  Expression forExpression;
  bool validPrefix = false;
  String property;

  // constructor

  UnknownPropertyDesc({required this.parent, required this.property, required this.forExpression})
      : super('') {
    if (parent is ClassDesc)
      validPrefix = (parent as ClassDesc).properties.keys.where((String prop) => prop.startsWith(property)).isNotEmpty;
  }
  
  // internal

  String methodSuggestion(MethodDesc prop) {
    final buffer = StringBuffer();

    buffer.write("${prop.name}(");

    var first = true;
    for (var param in prop.parameters) {
      if (!first)
        buffer.write(", ");

      buffer.write(param.name);

      first = false;
    }

    buffer.write(")");

    return buffer.toString();
  }

  // public

  Iterable<Suggestion> suggestions() {
    return parent is ClassDesc ? (parent as ClassDesc).properties.values
        .where((desc) => desc.name.startsWith(property))
        .map((prop) => Suggestion(
              suggestion:  prop.isField() ? prop.name : methodSuggestion(prop as MethodDesc),
              type: prop.isField() ? "field" : "method",
              tooltip: "")) : [];
  }
}

class ClassDescTypeResolver extends TypeResolver<ClassDescTypeInfo> {
  // instance data

  ClassDescTypeInfo root;
  final bool fail;
  Map<String,Desc> types = {};
  final Map<String,Desc> variables;


  Desc getType(String name) {
    var result = types[name];
    if ( result == null) {
      result = Desc.getType(name);
      types[name] = result;
    }

    return result;
  }

  // constructor

  ClassDescTypeResolver({required ClassDesc root, this.fail = false, required this.variables}): root = ClassDescTypeInfo(root, null);

  // internal

  Desc unknownType(Desc parent, String property, Expression expression) {
    if (fail)
      throw TypeException("unknown property $property");
    else
      return UnknownPropertyDesc(parent: parent, property: property, forExpression: expression);
  }

  // override

  @override
  TypeCheckerContext makeContext() {
    return ClassTypeCheckerContext();
  }

  @override
  void checkArguments(dynamic descriptor, List<TypeInfo> arguments) {
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
  ClassDescTypeInfo resolve(String name, {required Expression forExpression, ClassDescTypeInfo? parent}) {
    if ( variables.containsKey(name)) {
      return ClassDescTypeInfo(variables[name]!, null);
    }

    var parentType = (parent ?? root).type;

    if ( parentType is ClassDesc) {
      var property  = parentType.find(name);
      return ClassDescTypeInfo(property?.type ?? unknownType(parentType, name, forExpression), property);
    }
    else
      return ClassDescTypeInfo(unknownType(parentType, name, forExpression), null);
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

class TypeCheckerContext<TI> extends VisitorContext {
  bool isValid() {
    return true;
  }

  TI resolved(TI type) {
    return type;
  }
}

class ClassTypeCheckerContext extends TypeCheckerContext<ClassDescTypeInfo> {
  // instance data

  List<UnknownPropertyDesc> unknown = [];

  // public

  bool validPrefix() {
    if (unknown.isEmpty)
      return true;

    for ( var unknownType in unknown) {
      if (!unknownType.validPrefix)
        return false;
    }

    return true;
  }

  // override

  @override
  bool isValid() {
    return unknown.isEmpty;
  }

  @override
  ClassDescTypeInfo resolved(ClassDescTypeInfo type) {
    if ( type.type is UnknownPropertyDesc)
      unknown.add(type.type as UnknownPropertyDesc);

    return type;
  }
}


class TypeChecker<TI extends TypeInfo> implements ExpressionVisitor<TI, TypeCheckerContext<TI>> {
  // instance data

  final TypeResolver<TI> resolver;
  final bool fail;

  // constructor

  TypeChecker(this.resolver, {this.fail = false});
  
  // internal
  
  TI resolve(String name, {required Expression forExpression, TI? parent}) {
    TI type = resolver.resolve(name, parent: parent, forExpression: forExpression);

    return type;
  }

  // override

  @override
  TI visitLiteral(Literal expr, TypeCheckerContext<TI> context) {
    return expr.type = resolver.resolveType(expr.value.runtimeType);
  }

  @override
  TI visitIdentifier(Identifier expr, TypeCheckerContext<TI> context) => expr.type = resolver.resolveType(String);

  @override
  TI visitVariable(Variable expr, TypeCheckerContext<TI> context) {
    return expr.type = context.resolved(resolver.resolve(expr.identifier.name, forExpression: expr));
  }

  @override
  TI visitUnary(UnaryExpression expr, TypeCheckerContext<TI> context) {
    expr.argument.accept(this, context);

    return resolver.resolveType(int); // TODO
  }

  @override
  TI visitBinary(BinaryExpression expr, TypeCheckerContext<TI> context) {
    expr.left.accept(this, context);
    expr.right.accept(this, context);

    return resolver.resolveType(int); // TODO
  }

  @override
  TI visitConditional(ConditionalExpression expr, TypeCheckerContext<TI> context) {
    expr.test.accept(this, context);
    expr.consequent.accept(this, context);
    expr.alternate.accept(this, context);

    return resolver.resolveType(bool); // TODO
  }

  @override
  TI visitMember(MemberExpression expr, TypeCheckerContext<TI> context) {
    var objType = expr.object.accept(this, context);

    return expr.type = context.resolved(resolver.resolve(expr.property.name, parent: objType, forExpression: expr));
  }

  @override
  TI visitIndex(IndexExpression expr, TypeCheckerContext<TI> context) {
    expr.object.accept(this, context);
    expr.index.accept(this, context);

    return resolver.resolveType(int); // TODO
  }

  @override
  TI visitCall(CallExpression expr, TypeCheckerContext<TI> context) { // callee, arguments
    expr.callee.accept(this, context);

    // resolve arguments

    List<TI> argumentTypes = expr.arguments.map((arg) => arg.accept(this, context)).toList();

    if (expr.callee is Variable) {
      expr.type = context.resolved(resolver.resolve((expr.callee as Variable).identifier.name, forExpression: expr));
      resolver.checkArguments(expr.getDescriptor(), argumentTypes);
    }

    else if (expr.callee is MemberExpression) {
      final member = expr.callee as MemberExpression;
      TI? objType = member.object.type as TI?;

      resolver.checkArguments(member.getDescriptor(), argumentTypes);
      if (objType != null) {
        expr.type = context.resolved(resolver.resolve(member.property.name, parent: objType, forExpression: expr));
      }
    }

    return expr.type as TI;
  }

  @override
  TI visitThis(ThisExpression expr, TypeCheckerContext<TI> context) => expr.type = resolver.rootType();
}