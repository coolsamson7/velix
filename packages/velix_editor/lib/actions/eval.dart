

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

abstract class Eval {
  dynamic eval(dynamic value);
}

class This extends Eval {
  @override
  dynamic eval(dynamic value) {
    return value;
  }
}

class EvalValue extends Eval {
  // instance data

  dynamic value;

  // constructor

  EvalValue({required this.value});

  // override

  @override
  dynamic eval(dynamic value) {
    return this.value;
  }
}

class EvalField extends Eval {
  // instance data

  FieldDescriptor field;

  // constructor

  EvalField({required this.field});

  // override

  @override
  dynamic eval(dynamic value) {
    return field.get(value);
  }
}

class EvalMember extends Eval {
  // instance data

  Eval receiver;
  FieldDescriptor field;

  // constructor

  EvalMember({required this.receiver, required this.field});

  // override

  @override
  dynamic eval(dynamic value) {
    return field.get(receiver.eval(value));
  }
}

class EvalMethod extends Eval {
  // instance data

  Eval receiver;
  MethodDescriptor method;
  late List<Eval> arguments;

  // constructor

  EvalMethod({required this.receiver, required this.method});

  // override

  @override
  dynamic eval(dynamic value) {
    var args = arguments.map((arg) => arg.eval(value));

    return method.invoker!([receiver.eval(value), ...args]);
  }
}

class EvalVisitor extends ExpressionVisitor<Eval,CallVisitorContext> {
  // instance data

  final TypeDescriptor rootClass;

  // constructor

  EvalVisitor(this.rootClass);

  // visitors

  @override
  Eval visitLiteral(Literal expr, CallVisitorContext context) {
    if (expr.value is int)
      return EvalValue(value: expr.value);

    if (expr.value is String)
      return EvalValue(value: expr.value);

    if (expr.value is bool)
      return EvalValue(value: expr.value);

    return EvalValue(value: null); // TODO?
  }

  @override
  Eval visitVariable(Variable expr, CallVisitorContext context) {
    var property =  rootClass.getProperty(expr.identifier.name);
    return property.isField() ?
      EvalField(field: property as FieldDescriptor) :
      EvalMethod(receiver: This(), method: property as MethodDescriptor); // ?context.instance must be a call
  }

  @override
  Eval visitUnary(UnaryExpression expr, CallVisitorContext context) {
    return expr.argument.accept(this, context);
  }

  @override
  Eval visitMember(MemberExpression expr, CallVisitorContext context) {
    var receiver = expr.object.accept(this, context);
    var type = expr.object.getType<ObjectType>();

    var property =  expr.property.name;
    var descriptor = type.typeDescriptor.getProperty<AbstractPropertyDescriptor>(property);

    return descriptor.isField() ?
      EvalMember(receiver: receiver, field: descriptor as FieldDescriptor) :
      EvalMethod(receiver: receiver, method: descriptor as MethodDescriptor);
  }

  @override
  Eval visitThis(ThisExpression expr, CallVisitorContext context) {
    return This();
  }

  @override
  Eval visitCall(CallExpression expr, CallVisitorContext context) {
    var method = expr.callee.accept(this, context) as EvalMethod;

    method.arguments = expr.arguments.map((arg) => arg.accept(this, context)).toList();

    return method;
  }
}