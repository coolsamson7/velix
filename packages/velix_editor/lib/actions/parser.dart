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
          if (arg is Identifier) {
            // For member access, if it's an empty identifier (dangling dot),
            // extend its end to the current parsing position
            if (arg.name.isEmpty) {
              arg.end = end;
            }
            obj = MemberExpression(obj, arg)
              ..start = obj.start
              ..end = arg.end;
          } else if (arg is Expression) {
            obj = IndexExpression(obj, arg)
              ..start = obj.start
              ..end = arg.end;
          } else if (arg is List<Expression>) {
            obj = CallExpression(obj, arg)
              ..start = obj.start
              ..end = arg.isNotEmpty ? arg.last.end : obj.end;
          }
        }

        // Set the final bounds to the full parsed span
        obj.start = start;
        obj.end = end;

        return obj;
      });

  Parser<Expression> memberAccess() =>
      (char('.') & partialIdentifier().optional())
          .mapWithPosition((list, start, end) {
        final id = list[1]; // partialIdentifier result
        if (id != null) {
          return id;
        } else {
          // For dangling dot, create empty identifier starting after the dot
          // The end position will be fixed by the parent variable() parser
          return Identifier('')..start = end..end = end;
        }
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

  // Fixed: Properly handle comma-separated arguments
  Parser<List<Expression>> get arguments {
    // Non-empty argument list: expression followed by zero or more (comma + expression)
    final nonEmptyArgs = (expression & (char(',').trim() & expression).star())
        .map<List<Expression>>((values) {
      final first = values[0] as Expression;
      final rest = values[1] as List;
      final result = <Expression>[first];

      for (var pair in rest) {
        // pair is a list: [comma_char, expression]
        // The & operator ensures both comma AND expression must be present
        result.add(pair[1] as Expression);
      }
      return result;
    });

    // Allow either non-empty args or empty args (for empty parentheses)
    return nonEmptyArgs.or(epsilon().map((_) => <Expression>[])).cast<List<Expression>>();
  }

  Parser<List<Expression>> conditionArguments() =>
      (char('?') & expression & char(':') & expression).pick(1).seq(expression)
          .map((l) => [l[0], l[1]]);

  Parser<Expression> literal() =>
      numericLiteral().or(stringLiteral()).or(boolLiteral()).or(nullLiteral()).cast();

  Parser<Expression> numericLiteral() {
    // Matches: digits optionally followed by .digits
    final number = (digit().plus() & (char('.') & digit().plus()).optional())
        .flatten();

    return number.mapWithPosition((v, start, end) {
      final value = v.contains('.') ? double.parse(v) : int.parse(v);
      return Literal(value, v)..start = start..end = end;
    });
  }

  // Fixed: Require closing quote for string literals
  Parser<Expression> stringLiteral() {
    // Match opening quote, content (anything except quote or newline), and closing quote
    final stringContent = (char('\\') & any()) // escaped character
        .or(pattern('^"\n\r')) // any char except quote or newline
        .star()
        .flatten();

    return (char('"') & stringContent & char('"'))
        .pick(1)
        .mapWithPosition((v, start, end) =>
    Literal(v, '"$v"')..start = start..end = end);
  }

  Parser<Expression> boolLiteral() =>
      (string('true').or(string('false')))
          .mapWithPosition((v, start, end) =>
      Literal(v == 'true', v)..start = start..end = end);

  Parser<Expression> nullLiteral() =>
      string('null').mapWithPosition((_, start, end) =>
      Literal(null, 'null')..start = start..end = end);

// unaryExpression
  Parser<Expression> unaryExpression() {
    final ops = ['-', '+', '!', '~'];
    final List<Parser<String>> parsers = ops.map((s) => string(s)).toList();

    final Parser<String> op = ChoiceParser<String>(parsers).trim();

    return (op & token).mapWithPosition((values, start, end) {
      final operator = values[0] as String;
      final expr = values[1] as Expression;
      return UnaryExpression(operator, expr)
        ..start = start
        ..end = end;
    });
  }


  Parser<Expression> binaryExpression() =>
      token.plusSeparated(binaryOperation()).map((sl) {
        final elements = sl.elements;
        final separators = sl.separators;

        // Left-associative chaining
        Expression left = elements.first;
        for (int i = 0; i < separators.length; i++) {
          final op = separators[i];
          final right = elements[i + 1];
          left = BinaryExpression(op, left, right)
            ..start = left.start
            ..end = right.end;
        }

        return left;
      });


  Parser<String> binaryOperation() =>
      ['+', '-', '*', '/', '%', '==', '!=', '<', '>', '<=', '>=']
          .map(string)
          .reduce((a, b) => a.or(b).cast<String>())
          .trim();
}