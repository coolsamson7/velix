import 'expressions.dart';

abstract class ExpressionVisitor<T> {
  T visitLiteral(Literal expr) { throw UnimplementedError("NYI");}

  T visitIdentifier(Identifier expr) { throw UnimplementedError("NYI");}

  T visitVariable(Variable expr) { throw UnimplementedError("NYI");}

  T visitUnary(UnaryExpression expr) { throw UnimplementedError("NYI");}

  T visitBinary(BinaryExpression expr) { throw UnimplementedError("NYI");}

  T visitConditional(ConditionalExpression expr) { throw UnimplementedError("NYI");}

  T visitMember(MemberExpression expr) { throw UnimplementedError("NYI");}

  T visitIndex(IndexExpression expr) { throw UnimplementedError("NYI");}

  T visitCall(CallExpression expr) { throw UnimplementedError("NYI");}

  T visitThis(ThisExpression expr) { throw UnimplementedError("NYI");}
}