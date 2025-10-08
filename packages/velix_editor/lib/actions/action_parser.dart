import 'package:petitparser/petitparser.dart';

import 'expressions.dart';
import 'infer_types.dart';
import 'parser.dart';

/// Standardized result type for both modes.
class ParseResult {
  //instance data

  final bool success;
  final Expression? value;
  final bool complete;
  final String? message;
  final int? position;

  // constructor

  ParseResult._({
    required this.success,
    this.value,
    required this.complete,
    this.message,
    this.position,
  });

  factory ParseResult.success(Expression? value, {required bool complete}) {
    return ParseResult._(success: true, value: value, complete: complete);
  }

  factory ParseResult.failure(String message, [int? position]) {
    return ParseResult._(
      success: false,
      value: null,
      complete: false,
      message: message,
      position: position,
    );
  }
}

class ActionParser {
  // static singleton instance (initialized on first call)

  static final ActionParser _instance = ActionParser._internal();

  // public getter

  static ActionParser get instance => _instance;

  // private constructor

  ActionParser._internal();

  // instance data

  final parser = ExpressionParser();

  // public

  ParseResult parsePrefix(String input, { TypeChecker? typeChecker}) {
    final result = parser.expression.parse(input);
    if (result is Success<Expression>) {
      var complete = result.position == result.buffer.length;

      // check types

      var valid = true;
      var message = "";
      if (typeChecker != null) {
        var expr = result.value;

        var context = ClassTypeCheckerContext();

        try {
          expr.accept(typeChecker, context);

          valid = context.validPrefix();
          if (!valid)
            message = "unknown property ${context.unknown[0].property}";

          complete = context.unknown.isEmpty;
        }
        catch(e) {
          valid = false;
          message = e.toString();
        }
      }

      // done

      if (valid)
        return ParseResult.success(result.value, complete: complete);
      else
        return ParseResult.failure(message, result.position);
    }
    return ParseResult.failure(result.message, result.position);
  }

  /// Parse input requiring complete success.
  ParseResult parseStrict(String input, { TypeChecker? typeChecker}) {
    final result = parser.expression.end().parse(input);
    if (result is Success<Expression>) {
      // check types

      var valid = true;
      var message = "unknown property";
      if (typeChecker != null) {
        var expr = result.value;
// TODO this sucks
        var runtime = typeChecker.resolver is RuntimeTypeTypeResolver;

        var context = runtime ? TypeCheckerContext<RuntimeTypeInfo>() : ClassTypeCheckerContext();

        try {
          expr.accept(typeChecker, context);

          if (!runtime) {
            valid = (context as ClassTypeCheckerContext).unknown.isEmpty;
            if (!valid) {
              message = "unknown property " + (context as ClassTypeCheckerContext).unknown[0].property;
            }
          }
        }
        catch(e) {
          valid = false;
          message = e.toString();
        }
      }

      // done

      if (valid)
        return ParseResult.success(result.value, complete: true);
      else
        return ParseResult.failure(message, result.position);
    }
    return ParseResult.failure(result.message, result.position);
  }

  Expression parse(String input) {
    var result = parser.expression.parse(input);

    if (result is Success<Expression>) {
      final expr = result.value;

      return expr;
    }
    else {
      throw Exception((result as Failure).message);
    }
  }
}


extension AutoCompleteParser on ActionParser {
  /// Try to parse input but return suggestions if parsing failed.
  AutoCompleteResult tryAutoComplete(String input) {
    // Attempt strict parsing
    final result = parser.expression.end().parse(input);

    if (result is Success) {
      // Already valid & complete, no suggestions needed
      return AutoCompleteResult.complete(result.value);
    }

    if (result is Failure) {
      // PetitParser error messages usually say what was expected
      final expected = result.message;
      final pos = result.position;

      return AutoCompleteResult.incomplete(
        input: input,
        position: pos,
        expected: expected,
      );
    }

    // Fallback
    return AutoCompleteResult.unknown();
  }
}

/// Result type specialized for auto-completion
class AutoCompleteResult {
  // instance data

  final bool valid;
  final bool complete;
  final dynamic value;
  final String? expected;
  final int? position;
  final String? input;

  // constructor

  AutoCompleteResult._({
    required this.valid,
    required this.complete,
    this.value,
    this.expected,
    this.position,
    this.input,
  });

  factory AutoCompleteResult.complete(dynamic value) {
    return AutoCompleteResult._(valid: true, complete: true, value: value);
  }

  factory AutoCompleteResult.incomplete({
    required String input,
    required int position,
    required String expected,
  }) {
    return AutoCompleteResult._(
      valid: false,
      complete: false,
      input: input,
      position: position,
      expected: expected,
    );
  }

  factory AutoCompleteResult.unknown() {
    return AutoCompleteResult._(valid: false, complete: false);
  }
}

void main() {
  var result = ActionParser.instance.parsePrefix("user.hello(");

  result = ActionParser.instance.parseStrict("user.hello(");

  var r =  ActionParser.instance.tryAutoComplete('user.hello(user.name');
  print("valid=${r.valid}, complete=${r.complete}, expected=${r.expected}");
  // → valid=false, complete=false, expected="')' expected"

  r =  ActionParser.instance.tryAutoComplete('user.hello(');
  print("valid=${r.valid}, complete=${r.complete}, expected=${r.expected}");
  // → valid=false, complete=false, expected="')' expected"

  r =  ActionParser.instance.tryAutoComplete('user.hello(1');
  print("valid=${r.valid}, complete=${r.complete}, expected=${r.expected}");

  r =  ActionParser.instance.tryAutoComplete('user.hello(1,');
  print("valid=${r.valid}, complete=${r.complete}, expected=${r.expected}");

  r = ActionParser.instance.tryAutoComplete('user.hello(1)');
  print("valid=${r.valid}, complete=${r.complete}");
  // → valid=true, complete=true
}