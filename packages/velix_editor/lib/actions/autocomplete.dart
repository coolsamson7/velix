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

class CompletionContext {
  final int tokenStart;
  final int tokenEnd;
  final String tokenType;
  final Expression node;

  CompletionContext({
    required this.tokenStart,
    required this.tokenEnd,
    required this.tokenType,
    required this.node,
  });
}

class Autocomplete {
  // instance data

  final ActionParser parser = ActionParser.instance;
  final TypeChecker typeChecker;

  // constructor

  Autocomplete({required this.typeChecker});

  // public

  /// Get the token boundaries at the cursor position for inline completion
  CompletionContext? getCompletionContext(String input, int cursorOffset) {
    if (cursorOffset == -1) {
      cursorOffset = input.length;
    }

    var result = parser.parsePrefix(input, typeChecker: typeChecker);

    if (!result.success || result.value == null) {
      return null;
    }

    final node = _findNodeAt(result.value!, cursorOffset);
    if (node == null) {
      return null;
    }

    // Determine what part of the node is being completed
    int tokenStart;
    int tokenEnd;
    String tokenType;

    if (node is MemberExpression) {
      // Completing the property name after the dot
      // e.g., "user.na|me" - we want token boundaries of "name"
      tokenStart = node.property.start;
      tokenEnd = node.property.end;
      tokenType = "property";
    }
    else if (node is Variable) {
      // Completing a variable name
      // e.g., "us|er" - we want token boundaries of "user"
      tokenStart = node.identifier.start;
      tokenEnd = node.identifier.end;
      tokenType = "variable";
    }
    else if (node is Identifier) {
      // Direct identifier completion
      tokenStart = node.start;
      tokenEnd = node.end;
      tokenType = "identifier";
    }
    else if (node is CallExpression) {
      // Check if we're on the callee (function name)
      if (cursorOffset >= node.callee.start && cursorOffset <= node.callee.end) {
        // Recursively get context for the callee
        final calleeContext = _getNodeContext(node.callee, cursorOffset);
        if (calleeContext != null) return calleeContext;
      }
      // Otherwise we're in arguments
      tokenStart = node.start;
      tokenEnd = node.end;
      tokenType = "call";
    }
    else {
      // Fallback to the node boundaries
      tokenStart = node.start;
      tokenEnd = node.end;
      tokenType = node.runtimeType.toString().toLowerCase();
    }

    return CompletionContext(
      tokenStart: tokenStart,
      tokenEnd: tokenEnd,
      tokenType: tokenType,
      node: node,
    );
  }

// Helper to extract context from a specific node
  CompletionContext? _getNodeContext(Expression node, int cursorOffset) {
    if (node is MemberExpression) {
      return CompletionContext(
        tokenStart: node.property.start,
        tokenEnd: node.property.end,
        tokenType: "property",
        node: node,
      );
    } else if (node is Variable) {
      return CompletionContext(
        tokenStart: node.identifier.start,
        tokenEnd: node.identifier.end,
        tokenType: "variable",
        node: node,
      );
    } else if (node is Identifier) {
      return CompletionContext(
        tokenStart: node.start,
        tokenEnd: node.end,
        tokenType: "identifier",
        node: node,
      );
    }
    return null;
  }


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
                suggestion: prop.isField() ? prop.name : methodSuggestion(prop as MethodDesc),
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

  String methodSuggestion(MethodDesc prop) {
    final buffer = StringBuffer();

    buffer.write("${prop.name}(");

    var first = true;
    for (var param in prop.parameters) {
      if (!first)
        buffer.write(", ");

      buffer.write(param.name);

      first = false;
    }

    buffer.write(")");

    return buffer.toString();
  }
}
