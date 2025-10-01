import 'package:petitparser/petitparser.dart';

import 'expressions.dart';
import 'parser.dart';

class ActionParser {
  // private constructor
  ActionParser._internal();

  // static singleton instance (initialized on first call)
  static final ActionParser _instance = ActionParser._internal();

  // public getter
  static ActionParser get instance => _instance;

  // instance data

  final parser = ExpressionParser();

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