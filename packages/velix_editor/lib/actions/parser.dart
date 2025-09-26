import 'package:petitparser/petitparser.dart';

import 'expressions.dart';

// Parser Extension for Offsets
extension MapWithPositionExt<T> on Parser<T> {
  Parser<R> mapWithPosition<R>(R Function(T value, int start, int end) mapper) {
    return (position() & flatten()).map((values) {
      final start = values[0] as int;
      final text = values[1] as String;
      final end = start + text.length;

      // Parse the inner parser again to get the value
      final innerResult = parse(text);
      if (innerResult is Success) {
        return mapper(innerResult.value, start, end);
      }
      else {
        throw innerResult;
      }
    });
  }
}

// the parser

class ExpressionParser {
  // instance data

  late final SettableParser<Expression> expression;
  late final SettableParser<Expression> token;

  // constructor

  ExpressionParser() {
    expression = SettableParser<Expression>(undefined<Expression>());
    token = SettableParser<Expression>(undefined<Expression>());

    token.set(
      literal()
          .or(unaryExpression())
          .or(variable())
          .or(partialVariable())
          .cast<Expression>(),
    );

    expression.set(
      binaryExpression()
          .seq(conditionArguments().optional())
          .map((l) {
        if (l[1] == null) return l[0];
        return ConditionalExpression(l[0], l[1][0], l[1][1])
          ..start = l[0].start
          ..end = l[1][1].end;
      }),
    );
  }

  Parser<Expression> partialVariable() =>
      partialIdentifier().map((id) => Variable(id)..start = id.start..end = id.end);

  Parser<Identifier> partialIdentifier() =>
      (letter() & (word() | char(r'$')).star())
          .flatten()
          .mapWithPosition((v, start, end) => Identifier(v)..start = start..end = end);

  Parser<Expression> variable() =>
      groupOrIdentifier()
          .seq((memberAccess().or(indexArgument()).or(callArgument())).star())
          .mapWithPosition((list, start, end) {
        Expression obj = list[0];
        final args = list[1] as List;
        for (var arg in args) {
          if (arg is Identifier) obj = MemberExpression(obj, arg)..end = end;
          else if (arg is Expression) obj = IndexExpression(obj, arg)..end = end;
          else if (arg is List<Expression>) obj = CallExpression(obj, arg)..end = end;
        }
        obj.start = start;
        obj.end = end;
        return obj;
      });

  Parser<Expression> memberAccess() =>
      (char('.') & partialIdentifier().optional()).pick(1).map((id) {
        return id ?? Identifier(''); // empty identifier for dangling dot
      });

  Parser<Expression> indexArgument() =>
      (char('[') & expression & char(']')).pick(1).cast<Expression>();

  Parser<List<Expression>> callArgument() =>
      (char('(') & arguments & char(')')).pick(1).cast();

  Parser<Expression> group() =>
      (char('(') & expression & char(')')).pick(1).cast();

  Parser<Expression> groupOrIdentifier() =>
      group().or(thisExpression()).or(identifier().map((v) => Variable(v))).cast();

  Parser<Identifier> identifier({bool partial = false}) =>
      (letter() & (word() | char(r'$')).star())
          .flatten()
          .mapWithPosition((v, start, end) => Identifier(v)..start = start..end = end);

  Parser<Expression> thisExpression() =>
      string('this').mapWithPosition((_, start, end) {
        final t = ThisExpression();
        t.start = start;
        t.end = end;
        return t;
      });

  Parser<List<Expression>> get arguments =>
      expression.plusSeparated(char(',').trim()).map((sl) => sl.elements).optionalWith([]);

  Parser<List<Expression>> conditionArguments() =>
      (char('?') & expression & char(':') & expression).pick(1).seq(expression)
          .map((l) => [l[0], l[1]]);

  Parser<Expression> literal() =>
      numericLiteral().or(stringLiteral()).or(boolLiteral()).or(nullLiteral()).cast();

  Parser<Expression> numericLiteral() =>
      digit().plus().flatten().mapWithPosition((v, start, end) =>
      Literal(int.parse(v), v)..start = start..end = end);

  Parser<Expression> stringLiteral() =>
      (char('"') & pattern('^"').star().flatten() & char('"'))
          .pick(1)
          .mapWithPosition((v, start, end) =>
      Literal(v, '"$v"')..start = start..end = end);

  Parser<Expression> boolLiteral() =>
      (string('true').or(string('false')))
          .mapWithPosition((v, start, end) =>
      Literal(v == 'true', v)..start = start..end = end);

  Parser<Expression> nullLiteral() =>
      string('null').mapWithPosition((_, start, end) =>
      Literal(null, 'null')..start = start..end = end);

  Parser<Expression> unaryExpression() {
    final ops = ['-', '+', '!', '~'];
    return ops.map(string).reduce((a, b) => a.or(b).cast<String>())
        .trim()
        .seq(token)
        .mapWithPosition((list, start, end) => UnaryExpression(list[0], list[1])..start = start..end = end);
  }

  Parser<Expression> binaryExpression() =>
      token.plusSeparated(binaryOperation())
          .map((sl) {
        final elements = sl.elements;
        Expression left = elements[0];
        for (int i = 1; i < elements.length; i += 2) {
          final op = elements[i] as String;
          final right = elements[i + 1];

          left = BinaryExpression(op, left, right)..start = left.start..end = right.end;
        }

        return left;
      });

  Parser<String> binaryOperation() =>
      ['+', '-', '*', '/', '%', '==', '!=', '<', '>', '<=', '>=']
          .map(string)
          .reduce((a, b) => a.or(b).cast<String>())
          .trim();
}