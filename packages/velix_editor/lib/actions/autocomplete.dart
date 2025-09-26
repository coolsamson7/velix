import 'expressions.dart';
import 'infer_types.dart';
import 'types.dart';

class Autocomplete {
  final ClassDesc root;

  Autocomplete(this.root);

  /// Returns autocomplete suggestions at cursor position in `expr`.
  List<String> suggest(Expression expr, int cursorOffset, [String fullInput = '']) {
    // Find the deepest node at the cursor
    final node = _findNodeAt(expr, cursorOffset);
    if (node == null) return [];

    // Determine if there is a dot prefix before the cursor
    String prefix = '';
    if (fullInput.isNotEmpty) {
      final beforeCursor = fullInput.substring(0, cursorOffset);
      final lastDot = beforeCursor.lastIndexOf('.');
      if (lastDot >= 0) {
        prefix = beforeCursor.substring(lastDot + 1);
      }
      else {
        prefix = beforeCursor;
      }
    }

    // Infer the type of the object for member access
    ClassDesc? type = root;
    if (node is MemberExpression) {
      // cursor may be on property access, get type of object
      type = node.object.accept(TypeInferencer(root));
    }
    else if (node is Variable || node is Identifier) {
      type = node.accept(TypeInferencer(root));
    }
    else if (node is CallExpression) {
      type = node.accept(TypeInferencer(root));
    }
    else {
      type = root; // fallback
    }

    if (type == null) return [];

    // Return matching fields and methods
    final suggestions = <String>[];
    suggestions.addAll(root.fields.keys.where((k) => k.startsWith(prefix))); // TODO
    suggestions.addAll(root.methods.keys.where((k) => k.startsWith(prefix)));

    return suggestions;
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
