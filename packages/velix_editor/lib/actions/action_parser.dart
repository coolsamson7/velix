import 'package:petitparser/petitparser.dart';

import 'expressions.dart';
import 'parser.dart';

class ActionParser {
  // instance data

  final parser = ExpressionParser();

  // constructor

  ActionParser();

  // public

  Expression parse(String input) {
    var result = parser.expression.parse(input);

    if (result is Success<Expression>) {
      final expr = result.value;

      return expr;
    }
    else {
      throw Exception("ouch");
    }
  }
}