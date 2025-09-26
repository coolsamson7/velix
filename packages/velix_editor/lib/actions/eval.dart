

// will generate a call structure

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_editor/actions/infer_types.dart';
import 'package:velix_editor/actions/visitor.dart';

import 'expressions.dart';

abstract class Call {
  dynamic eval(dynamic value);
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

class CallVisitor extends ExpressionVisitor<Call> {
  // instance data

  final TypeDescriptor rootClass;

  // constructor

  CallVisitor(this.rootClass);

  // visitors

  @override
  Call visitLiteral(Literal expr) {
    if (expr.value is int)
      return Value(value: expr.value);

    if (expr.value is String)
      return Value(value: expr.value);

    if (expr.value is bool)
      return Value(value: expr.value);

    return Value(value: null); // TODO?
  }


  @override
  Call visitVariable(Variable expr) {
    var field =  rootClass.getField(expr.identifier.name);
    return Field(field: field);
  }

  @override
  Call visitUnary(UnaryExpression expr) {
    return expr.argument.accept(this);
  }

  @override
  Call visitMember(MemberExpression expr) {
    var receiver = expr.object.accept(this);
    var type = expr.object.getType<RuntimeTypeInfo>().type as ObjectType;

    var property =  expr.property.name;
    var descriptor = type.typeDescriptor.getProperty<AbstractPropertyDescriptor>(property);

    return descriptor.isField() ?
      Member(receiver: receiver, field: descriptor as FieldDescriptor) :
      Method(receiver: receiver, method: descriptor as MethodDescriptor);
  }

  @override
  Call visitCall(CallExpression expr) {
    var method = expr.callee.accept(this) as Method;

    method.arguments = expr.arguments.map((arg) => arg.accept(this)).toList();

    return method;
  }
}