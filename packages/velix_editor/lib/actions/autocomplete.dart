import 'action_parser.dart';
import 'expressions.dart';
import 'infer_types.dart';
import 'types.dart';

class Suggestion {
  // instance data

  String suggestion;
  String type;
  String tooltip;

  // constructor

  Suggestion({required this.suggestion, required this.type, this.tooltip = ""});

}

class Autocomplete {
  // instance data

  final ActionParser parser = ActionParser.instance;
  final TypeChecker typeChecker;

  // constructor

  Autocomplete({required this.typeChecker});

  // public

  /// Returns autocomplete suggestions at cursor position in `expr`.
  Iterable<Suggestion> suggest(String input, {int cursorOffset = -1, String fullInput = ""}) {
    if ( cursorOffset == -1)
      cursorOffset = input.length;

    var result = parser.parsePrefix(input, typeChecker: typeChecker);

    if (!result.success)
      return [];

    // Find the deepest node at the cursor

    final node = _findNodeAt(result.value!, cursorOffset);
    if (node == null)
      return [];

    // Determine if there is a dot prefix before the cursor

    if ( node is Variable) {
      if ( node.getType<Desc>() is UnknownPropertyDesc) {
        return node.getType<UnknownPropertyDesc>().suggestions();
      }
    }

    if ( node is MemberExpression) {
      if ( node.getType() is UnknownPropertyDesc)
        return node.getType<UnknownPropertyDesc>().suggestions();

      var type = node.object.getType();
      var property = node.property.name;

      if ( type is ClassDesc)
        return type.properties.values
            .where((prop) => prop.name.startsWith(property))
            .map((prop) => Suggestion(
                suggestion: prop.name,
                type: prop.isField() ? "field" : "method",
                tooltip: ""));
    }

    return [];
  }

  bool containsOffset(Expression expr, int offset) {
    if (expr.start == expr.end) {
      // Accept offsets exactly at the zero-length span start (e.g., trailing dot)
      return offset == expr.start;
    }
    return offset >= expr.start && offset < expr.end;
  }

  /// Recursively find the deepest AST node containing the cursor
  Expression? _findNodeAt(Expression expr, int offset) {
    if (offset < expr.start || offset > expr.end) return null;

    if (expr is MemberExpression) {
      final objNode = _findNodeAt(expr.object, offset);
      return objNode ?? expr;
    }
    else if (expr is IndexExpression) {
      final objNode = _findNodeAt(expr.object, offset);
      final idxNode = _findNodeAt(expr.index, offset);
      return objNode ?? idxNode ?? expr;
    }
    else if (expr is CallExpression) {
      final calleeNode = _findNodeAt(expr.callee, offset);
      for (var arg in expr.arguments) {
        final found = _findNodeAt(arg, offset);
        if (found != null) return found;
      }

      return calleeNode ?? expr;
    }

    return expr;
  }
}
