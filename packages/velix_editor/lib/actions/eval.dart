

// will generate a call structure

import 'package:velix/reflectable/reflectable.dart';
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

class MethodCall extends Call {
  // instance data

  MethodDescriptor method;

  // constructor

  MethodCall({required this.method});

  // override

  @override
  dynamic eval(dynamic value) {
    return method.invoker!([value]);
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
    var property =  expr.property.accept(this);

    return Member(receiver: receiver, field: (property as Field).field);
  }

  @override
  Call visitCall(CallExpression expr) {
    var calee = expr.callee.accept(this);

    /*if (expr.callee is Variable) {
      final name = (expr.callee as Variable).identifier.name;
      final method = rootClass.lookupMethod(name);
      if (method != null)
        return expr.type = method.returnType;
    }

    if (expr.callee is MemberExpression) {
      final member = expr.callee as MemberExpression;
      final objType = member.object.type;
      if (objType != null) {
        final method = objType.lookupMethod(member.property.name);
        if (method != null) return expr.type = method.returnType;
      }
    }*/

    throw Exception("k");

    //return MethodCall(method: null);
  }
}