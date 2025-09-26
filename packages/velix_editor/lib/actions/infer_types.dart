

import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/actions/visitor.dart';

import 'expressions.dart';

/// =======================
/// Visitor Interface
/// =======================

final classInt = ClassDesc("int");
final classString = ClassDesc("String");
final classBool = ClassDesc("bool");
final classDynamic = ClassDesc("dynamic");

/// =======================
/// Type Inferencer
/// =======================
class TypeInferencer implements ExpressionVisitor<ClassDesc> {
  final ClassDesc rootClass;

  TypeInferencer(this.rootClass);

  @override
  ClassDesc visitLiteral(Literal expr) {
    if (expr.value is int)
      return expr.type = classInt;

    if (expr.value is String)
      return expr.type = classString;

    if (expr.value is bool)
      return expr.type = classBool;

    return expr.type = classDynamic;
  }

  @override
  ClassDesc visitIdentifier(Identifier expr) => expr.type = classDynamic;

  @override
  ClassDesc visitVariable(Variable expr) {
    return expr.type = rootClass.lookupField(expr.identifier.name)?.type ?? classDynamic;
  }

  @override
  ClassDesc visitUnary(UnaryExpression expr) {
    expr.argument.accept(this);

    return expr.type = classInt;
  }

  @override
  ClassDesc visitBinary(BinaryExpression expr) {
    expr.left.accept(this);
    expr.right.accept(this);

    return expr.type = classInt;
  }

  @override
  ClassDesc visitConditional(ConditionalExpression expr) {
    expr.test.accept(this);
    expr.consequent.accept(this);
    expr.alternate.accept(this);

    return expr.type = classDynamic;
  }

  @override
  ClassDesc visitMember(MemberExpression expr) {
    expr.object.accept(this);

    final objType = expr.object.type;
    if (objType != null) {
      final field = objType.lookupField(expr.property.name);

      if (field != null)
        return expr.type = field.type;

      final method = objType.lookupMethod(expr.property.name);
      if (method != null)
        return expr.type = method.returnType;
    }

    return expr.type = classDynamic;
  }

  @override
  ClassDesc visitIndex(IndexExpression expr) {
    expr.object.accept(this);
    expr.index.accept(this);

    return expr.type = classDynamic;
  }

  @override
  ClassDesc visitCall(CallExpression expr) {
    expr.callee.accept(this);

    if (expr.callee is Variable) {
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
    }

    return expr.type = classDynamic;
  }

  @override
  ClassDesc visitThis(ThisExpression expr) => expr.type = rootClass;
}