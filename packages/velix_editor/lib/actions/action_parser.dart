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
      throw Exception((result as Failure).message);
    }
  }
}
/*
/// Example: wrap your grammar/parser here
class ExpressionParser {
  final Parser _expression;

  ExpressionParser(this._expression);

  /// Parse input allowing partial success (prefix mode).
  ParseResult parsePrefix(String input) {
    final result = _expression.parse(input);
    if (result.isSuccess) {
      final complete = result.position == result.buffer.length;
      return ParseResult.success(result.value, complete: complete);
    }
    return ParseResult.failure(result.message, result.position);
  }

  /// Parse input requiring complete success.
  ParseResult parseStrict(String input) {
    final result = _expression.end().parse(input);
    if (result.isSuccess) {
      return ParseResult.success(result.value, complete: true);
    }
    return ParseResult.failure(result.message, result.position);
  }
}

/// Standardized result type for both modes.
class ParseResult {
  final bool success;
  final dynamic value;
  final bool complete;
  final String? message;
  final int? position;

  ParseResult._({
    required this.success,
    this.value,
    required this.complete,
    this.message,
    this.position,
  });

  factory ParseResult.success(dynamic value, {required bool complete}) {
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

#extension AutoCompleteParser on ExpressionParser {
  /// Try to parse input but return suggestions if parsing failed.
  AutoCompleteResult tryAutoComplete(String input) {
    // Attempt strict parsing
    final result = _expression.end().parse(input);

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
  final bool valid;
  final bool complete;
  final dynamic value;
  final String? expected;
  final int? position;
  final String? input;

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
  final parser = ExpressionParser(buildMyGrammar());

  var r1 = parser.tryAutoComplete('user.hello(');
  print("valid=${r1.valid}, complete=${r1.complete}, expected=${r1.expected}");
  // → valid=false, complete=false, expected="')' expected"

  var r2 = parser.tryAutoComplete('user.hello(1)');
  print("valid=${r2.valid}, complete=${r2.complete}");
  // → valid=true, complete=true
}*/