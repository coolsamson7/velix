import 'expressions.dart';
import 'infer_types.dart';
import 'types.dart';

class Autocomplete {
  // instance data

  final ClassDesc root;
  final TypeResolver typeResolver;

  // constructor

  Autocomplete(this.root) :typeResolver = ClassDescTypeResolver(root: root);

  // public

  /// Returns autocomplete suggestions at cursor position in `expr`.
  List<String> suggest(Expression expr, int cursorOffset, [String fullInput = '']) {
    // check types

    expr.accept(TypeInferencer(typeResolver)); // TODO

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
    ClassDesc? type = (node.type as ClassDescTypeInfo).type;

    if ( type == null)
      return [];

    // Return matching fields and methods

    final suggestions = <String>[];
    //suggestions.addAll(root._.keys.where((k) => k.startsWith(prefix))); // TODO was type

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
