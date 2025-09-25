import 'package:highlight/languages/autohotkey.dart';
import 'package:petitparser/petitparser.dart';

/// =======================
/// Type System
/// =======================
class ClassDescriptor {
  final String name;
  final Map<String, FieldDescriptor> fields;
  final Map<String, MethodDescriptor> methods;

  ClassDescriptor(
      this.name, {
        Map<String, FieldDescriptor>? fields,
        Map<String, MethodDescriptor>? methods,
      })  : fields = fields ?? {},
        methods = methods ?? {};

  FieldDescriptor? lookupField(String name) => fields[name];
  MethodDescriptor? lookupMethod(String name) => methods[name];

  @override
  String toString() => name;
}

class FieldDescriptor {
  final String name;
  final ClassDescriptor type;
  FieldDescriptor(this.name, this.type);
}

class MethodDescriptor {
  final String name;
  final List<ClassDescriptor> parameterTypes;
  final ClassDescriptor returnType;

  MethodDescriptor(this.name, this.parameterTypes, this.returnType);
}

// Primitive types
final classInt = ClassDescriptor("int");
final classString = ClassDescriptor("String");
final classBool = ClassDescriptor("bool");
final classDynamic = ClassDescriptor("dynamic");

// Nested class type
final innerClass = ClassDescriptor(
  'Inner',
  fields: {'value': FieldDescriptor('value', classInt)},
  methods: {'doubleValue': MethodDescriptor('doubleValue', [], classInt)},
);

// Root class
final rootClass = ClassDescriptor(
  'Root',
  fields: {
    'x': FieldDescriptor('x', classInt),
    'inner': FieldDescriptor('inner', innerClass),
  },
  methods: {
    'sum': MethodDescriptor('sum', [classInt, classInt], classInt),
  },
);

/// =======================
/// AST Nodes
/// =======================
abstract class Expression {
  int start = 0;
  int end = 0;
  ClassDescriptor? type;
  T accept<T>(ExpressionVisitor<T> visitor);
}

class Identifier extends Expression {
  final String name;
  Identifier(this.name);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitIdentifier(this);
}

class Variable extends Expression {
  final Identifier identifier;
  Variable(this.identifier);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitVariable(this);
}

class Literal extends Expression {
  final Object? value;
  final String raw;
  Literal(this.value, this.raw);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitLiteral(this);
}

class UnaryExpression extends Expression {
  final String op;
  final Expression argument;
  UnaryExpression(this.op, this.argument);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitUnary(this);
}

class BinaryExpression extends Expression {
  final String op;
  final Expression left;
  final Expression right;
  BinaryExpression(this.op, this.left, this.right);
  static int precedence(String op) {
    const map = {
      '||': 1,
      '&&': 2,
      '|': 3,
      '^': 4,
      '&': 5,
      '==': 6,
      '!=': 6,
      '<=': 7,
      '>=': 7,
      '<': 7,
      '>': 7,
      '+': 8,
      '-': 8,
      '*': 9,
      '/': 9,
      '%': 9,
    };
    return map[op] ?? -1;
  }

  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitBinary(this);
}

class ThisExpression extends Expression {
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitThis(this);
}

class MemberExpression extends Expression {
  final Expression object;
  final Identifier property;
  MemberExpression(this.object, this.property);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitMember(this);
}

class IndexExpression extends Expression {
  final Expression object;
  final Expression index;
  IndexExpression(this.object, this.index);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitIndex(this);
}

class CallExpression extends Expression {
  final Expression callee;
  final List<Expression> arguments;
  CallExpression(this.callee, this.arguments);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) => visitor.visitCall(this);
}

class ConditionalExpression extends Expression {
  final Expression test, consequent, alternate;
  ConditionalExpression(this.test, this.consequent, this.alternate);
  @override
  T accept<T>(ExpressionVisitor<T> visitor) =>
      visitor.visitConditional(this);
}

/// =======================
/// Visitor Interface
/// =======================
abstract class ExpressionVisitor<T> {
  T visitLiteral(Literal expr);
  T visitIdentifier(Identifier expr);
  T visitVariable(Variable expr);
  T visitUnary(UnaryExpression expr);
  T visitBinary(BinaryExpression expr);
  T visitConditional(ConditionalExpression expr);
  T visitMember(MemberExpression expr);
  T visitIndex(IndexExpression expr);
  T visitCall(CallExpression expr);
  T visitThis(ThisExpression expr);
}

/// =======================
/// Type Inferencer
/// =======================
class TypeInferencer implements ExpressionVisitor<ClassDescriptor> {
  final ClassDescriptor rootClass;
  TypeInferencer(this.rootClass);

  @override
  ClassDescriptor visitLiteral(Literal expr) {
    if (expr.value is int) return expr.type = classInt;
    if (expr.value is String) return expr.type = classString;
    if (expr.value is bool) return expr.type = classBool;
    return expr.type = classDynamic;
  }

  @override
  ClassDescriptor visitIdentifier(Identifier expr) => expr.type = classDynamic;

  @override
  ClassDescriptor visitVariable(Variable expr) {
    return expr.type =
        rootClass.lookupField(expr.identifier.name)?.type ?? classDynamic;
  }

  @override
  ClassDescriptor visitUnary(UnaryExpression expr) {
    expr.argument.accept(this);
    return expr.type = classInt;
  }

  @override
  ClassDescriptor visitBinary(BinaryExpression expr) {
    expr.left.accept(this);
    expr.right.accept(this);
    return expr.type = classInt;
  }

  @override
  ClassDescriptor visitConditional(ConditionalExpression expr) {
    expr.test.accept(this);
    expr.consequent.accept(this);
    expr.alternate.accept(this);
    return expr.type = classDynamic;
  }

  @override
  ClassDescriptor visitMember(MemberExpression expr) {
    expr.object.accept(this);
    final objType = expr.object.type;
    if (objType != null) {
      final field = objType.lookupField(expr.property.name);
      if (field != null) return expr.type = field.type;
      final method = objType.lookupMethod(expr.property.name);
      if (method != null) return expr.type = method.returnType;
    }
    return expr.type = classDynamic;
  }

  @override
  ClassDescriptor visitIndex(IndexExpression expr) {
    expr.object.accept(this);
    expr.index.accept(this);
    return expr.type = classDynamic;
  }

  @override
  ClassDescriptor visitCall(CallExpression expr) {
    expr.callee.accept(this);
    if (expr.callee is Variable) {
      final name = (expr.callee as Variable).identifier.name;
      final method = rootClass.lookupMethod(name);
      if (method != null) return expr.type = method.returnType;
    }
    if (expr.callee is MemberExpression) {
      final member = expr.callee as MemberExpression;
      final objType = member.object.type;
      if (objType != null) {
        final method = objType.lookupMethod(member.property.name);
        if (method != null) return expr.type = method.returnType;
      }
    }
    return expr.type = classDynamic;
  }

  @override
  ClassDescriptor visitThis(ThisExpression expr) => expr.type = rootClass;
}

/// =======================
/// Parser Extension for Offsets
/// =======================
extension MapWithPositionExt<T> on Parser<T> {
  Parser<R> mapWithPosition<R>(R Function(T value, int start, int end) mapper) {
    return (position() & this.flatten()).map((values) {
      final start = values[0] as int;
      final text = values[1] as String;
      final end = start + text.length;

      // Parse the inner parser again to get the value
      final innerResult = this.parse(text);
      if (innerResult is Success) {
        return mapper(innerResult.value, start, end);
      } else {
        throw innerResult;
      }
    });
  }
}

/// =======================
/// Expression Parser
/// =======================
class ExpressionParser {
  late final SettableParser<Expression> expression;
  late final SettableParser<Expression> token;

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

  // ---------------------
  // Partial variable (for autocomplete)
  // ---------------------
  Parser<Expression> partialVariable() =>
      partialIdentifier().map((id) => Variable(id)..start = id.start..end = id.end);

  Parser<Identifier> partialIdentifier() =>
      (letter() & (word() | char(r'$')).star())
          .flatten()
          .mapWithPosition((v, start, end) => Identifier(v)..start = start..end = end);

  // ---------------------
  // Regular variable + member/index/call
  // ---------------------
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
          final right = elements[i + 1] as Expression;
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



// auto

class Autocomplete {
  final ClassDescriptor root;

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
      } else {
        prefix = beforeCursor;
      }
    }

    // Infer the type of the object for member access
    ClassDescriptor? type;
    if (node is MemberExpression) {
      // cursor may be on property access, get type of object
      type = node.object.accept(TypeInferencer(root));
    } else if (node is Variable || node is Identifier) {
      type = node.accept(TypeInferencer(root));
    } else if (node is CallExpression) {
      type = node.accept(TypeInferencer(root));
    } else {
      type = root; // fallback
    }

    if (type == null) return [];

    // Return matching fields and methods
    final suggestions = <String>[];
    suggestions.addAll(type.fields.keys.where((k) => k.startsWith(prefix)));
    suggestions.addAll(type.methods.keys.where((k) => k.startsWith(prefix)));
    return suggestions;
  }

  /// Recursively find the deepest AST node containing the cursor
  Expression? _findNodeAt(Expression expr, int offset) {
    if (offset < expr.start || offset > expr.end) return null;

    if (expr is MemberExpression) {
      final objNode = _findNodeAt(expr.object, offset);
      return objNode ?? expr;
    } else if (expr is IndexExpression) {
      final objNode = _findNodeAt(expr.object, offset);
      final idxNode = _findNodeAt(expr.index, offset);
      return objNode ?? idxNode ?? expr;
    } else if (expr is CallExpression) {
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



/// =======================
/// Main
/// =======================
void main() {
  final parser = ExpressionParser();
  var input = 'inner.doubleValue()';
  var result = parser.expression.parse(input);

  if (result is Success<Expression>) {
    final expr = result.value;
    print('Parsed: $expr');
    print('Start: ${expr.start}, End: ${expr.end}');
    final inferencer = TypeInferencer(rootClass);
    final type = expr.accept(inferencer);
    print('Inferred type: ${type.name}');
  } else {
    print('Parse error at position ${result.position}');
  }

  // autohotkey

  input = "inn";
  result = parser.expression.parse(input);

  if (result is Success<Expression>) {
    final expr = result.value;
    final cursorOffset = input.length; // cursor at end
    final autocomplete = Autocomplete(rootClass);

    final suggestions = autocomplete.suggest(expr, cursorOffset, input);
    print('Suggestions: $suggestions');
    // Expected output: ['value', 'doubleValue']
  }

}
