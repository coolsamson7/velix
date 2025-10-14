

// will generate a call structure

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_editor/actions/visitor.dart';

import 'expressions.dart';

class CallVisitorContext extends VisitorContext {
  // instance data

  final dynamic instance;

  // constructor

  CallVisitorContext({required this.instance});
}

abstract class Call {
  dynamic eval(dynamic value);
}

class This extends Call {
  @override
  dynamic eval(dynamic value) {
    return value;
  }
}

class Value extends Call {
  // instance data

  dynamic value;

  // constructor

  Value({required this.value});

  // override

  @override
  dynamic eval(dynamic value) {
    return this.value;
  }
}

class Field extends Call {
  // instance data

  FieldDescriptor field;

  // constructor

  Field({required this.field});

  // override

  @override
  dynamic eval(dynamic value) {
    return field.get(value);
  }
}

class Member extends Call {
  // instance data

  Call receiver;
  FieldDescriptor field;

  // constructor

  Member({required this.receiver, required this.field});

  // override

  @override
  dynamic eval(dynamic value) {
    return field.get(receiver.eval(value));
  }
}

class Method extends Call {
  // instance data

  Call receiver;
  MethodDescriptor method;
  late List<Call> arguments;

  // constructor

  Method({required this.receiver, required this.method});

  // override

  @override
  dynamic eval(dynamic value) {
    var args = arguments.map((arg) => arg.eval(value));

    return method.invoker!([receiver.eval(value), ...args]);
  }
}

class CallVisitor extends ExpressionVisitor<Call,CallVisitorContext> {
  // instance data

  final TypeDescriptor rootClass;

  // constructor

  CallVisitor(this.rootClass);

  // visitors

  @override
  Call visitLiteral(Literal expr, CallVisitorContext context) {
    if (expr.value is int)
      return Value(value: expr.value);

    if (expr.value is String)
      return Value(value: expr.value);

    if (expr.value is bool)
      return Value(value: expr.value);

    return Value(value: null); // TODO?
  }

  @override
  Call visitVariable(Variable expr, CallVisitorContext context) {
    var property =  rootClass.getProperty(expr.identifier.name);
    return property.isField() ?
      Field(field: property as FieldDescriptor) :
      Method(receiver: This(), method: property as MethodDescriptor); // ?context.instance must be a call
  }

  @override
  Call visitUnary(UnaryExpression expr, CallVisitorContext context) {
    return expr.argument.accept(this, context);
  }

  @override
  Call visitMember(MemberExpression expr, CallVisitorContext context) {
    var receiver = expr.object.accept(this, context);
    var type = expr.object.getType<ObjectType>();

    var property =  expr.property.name;
    var descriptor = type.typeDescriptor.getProperty<AbstractPropertyDescriptor>(property);

    return descriptor.isField() ?
      Member(receiver: receiver, field: descriptor as FieldDescriptor) :
      Method(receiver: receiver, method: descriptor as MethodDescriptor);
  }

  @override
  Call visitThis(ThisExpression expr, CallVisitorContext context) {
    return This();
  }

  @override
  Call visitCall(CallExpression expr, CallVisitorContext context) {
    var method = expr.callee.accept(this, context) as Method;

    method.arguments = expr.arguments.map((arg) => arg.accept(this, context)).toList();

    return method;
  }
}