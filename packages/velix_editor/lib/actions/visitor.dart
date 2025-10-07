import 'expressions.dart';

class VisitorContext {}

abstract class ExpressionVisitor<T,C extends VisitorContext> {
  T visitLiteral(Literal expr, C context) { throw UnimplementedError("NYI");}

  T visitIdentifier(Identifier expr, C context) { throw UnimplementedError("NYI");}

  T visitVariable(Variable expr, C context) { throw UnimplementedError("NYI");}

  T visitUnary(UnaryExpression expr, C context) { throw UnimplementedError("NYI");}

  T visitBinary(BinaryExpression expr, C context) { throw UnimplementedError("NYI");}

  T visitConditional(ConditionalExpression expr, C context) { throw UnimplementedError("NYI");}

  T visitMember(MemberExpression expr, C context) { throw UnimplementedError("NYI");}

  T visitIndex(IndexExpression expr, C context) { throw UnimplementedError("NYI");}

  T visitCall(CallExpression expr, C context) { throw UnimplementedError("NYI");}

  T visitThis(ThisExpression expr, C context) { throw UnimplementedError("NYI");}
}