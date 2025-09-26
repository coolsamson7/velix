import 'package:velix_editor/actions/visitor.dart';

import 'infer_types.dart';

abstract class Expression {
  // instance data

  int start = 0;
  int end = 0;
  TypeInfo? type;

  T getType<T>() => type as T;

  // abstract

  T accept<T>(ExpressionVisitor<T> visitor);
}

class Identifier extends Expression {
  // instance data

  final String name;

  // constructor

  Identifier(this.name);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitIdentifier(this);
}

class Variable extends Expression {
  // instance data

  final Identifier identifier;

  // constructor

  Variable(this.identifier);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitVariable(this);
}

class Literal extends Expression {
  // instance data

  final Object? value;
  final String raw;

  // constructor

  Literal(this.value, this.raw);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitLiteral(this);
}

class UnaryExpression extends Expression {
  // instance data

  final String op;
  final Expression argument;

  // constructor

  UnaryExpression(this.op, this.argument);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitUnary(this);
}

class BinaryExpression extends Expression {
  // instance data

  final String op;
  final Expression left;
  final Expression right;

  // constructor

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

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitBinary(this);
}

class ThisExpression extends Expression {
  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitThis(this);
}

class MemberExpression extends Expression {
  // instance data

  final Expression object;
  final Identifier property;

  // constructor

  MemberExpression(this.object, this.property);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitMember(this);
}

class IndexExpression extends Expression {
  // instance data

  final Expression object;
  final Expression index;

  // constructor

  IndexExpression(this.object, this.index);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitIndex(this);
}

class CallExpression extends Expression {
  // instance data

  final Expression callee;
  final List<Expression> arguments;

  CallExpression(this.callee, this.arguments);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitCall(this);
}

class ConditionalExpression extends Expression {
  // instance data

  final Expression test, consequent, alternate;

  // constructor

  ConditionalExpression(this.test, this.consequent, this.alternate);

  // override

  @override
  T accept<T>(ExpressionVisitor<T> visitor) =>
      visitor.visitConditional(this);
}