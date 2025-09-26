import 'package:velix_editor/actions/visitor.dart';

import 'infer_types.dart';

/// AST Nodes
/// =======================
///
abstract class Expression {
  int start = 0;
  int end = 0;
  TypeInfo? type;

  T accept<T>(ExpressionVisitor<T> visitor);
}

class Identifier extends Expression {
  final String name;

  Identifier(this.name);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitIdentifier(this);
}

class Variable extends Expression {
  final Identifier identifier;

  Variable(this.identifier);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitVariable(this);
}

class Literal extends Expression {
  final Object? value;
  final String raw;

  Literal(this.value, this.raw);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitLiteral(this);
}

class UnaryExpression extends Expression {
  final String op;
  final Expression argument;

  UnaryExpression(this.op, this.argument);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitUnary(this);
}

class BinaryExpression extends Expression {
  final String op;
  final Expression left;
  final Expression right;
  BinaryExpression(this.op, this.left, this.right);
  static int precedence(String op) {
    const map = {
      '||': 1,
      '&&': 2,
      '|': 3,
      '^': 4,
      '&': 5,
      '==': 6,
      '!=': 6,
      '<=': 7,
      '>=': 7,
      '<': 7,
      '>': 7,
      '+': 8,
      '-': 8,
      '*': 9,
      '/': 9,
      '%': 9,
    };
    return map[op] ?? -1;
  }

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitBinary(this);
}

class ThisExpression extends Expression {
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitThis(this);
}

class MemberExpression extends Expression {
  final Expression object;
  final Identifier property;

  MemberExpression(this.object, this.property);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitMember(this);
}

class IndexExpression extends Expression {
  final Expression object;
  final Expression index;

  IndexExpression(this.object, this.index);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitIndex(this);
}

class CallExpression extends Expression {
  final Expression callee;
  final List<Expression> arguments;

  CallExpression(this.callee, this.arguments);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitCall(this);
}

class ConditionalExpression extends Expression {
  final Expression test, consequent, alternate;

  ConditionalExpression(this.test, this.consequent, this.alternate);

  @override
  T accept<T>(ExpressionVisitor<T> visitor) =>
      visitor.visitConditional(this);
}