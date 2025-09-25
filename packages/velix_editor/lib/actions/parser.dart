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
/// Expression Parser
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
      }
      else {
        throw innerResult; // propagate failure
      }
    });
  }
}





/// =======================
/// Expression Parser with Offsets
/// =======================
class ExpressionParser {
  late final SettableParser<Expression> expression;
  late final SettableParser<Expression> token;

  ExpressionParser() {
    expression = SettableParser<Expression>(undefined<Expression>());
    token = SettableParser<Expression>(undefined<Expression>());

    token.set(literal().or(unaryExpression()).or(variable()).cast<Expression>());

    expression.set(
      binaryExpression()
          .seq(conditionArguments().optional())
          .map((l) {
        if (l[1] == null) {
          return l[0];
        } else {
          final result = ConditionalExpression(l[0], l[1][0], l[1][1]);
          _assignOffsets(result, l);
          return result;
        }
      }),
    );
  }

  void _assignOffsets(Expression expr, List<dynamic> source) {
    expr.start = (source[0] as Expression).start;
    if (source.length > 1 && source[1] is List && (source[1] as List).length > 1) {
      expr.end = (source[1] as List)[1].end;
    } else {
      expr.end = expr.start;
    }
  }

  Parser<Expression> literal() => numericLiteral()
      .or(stringLiteral())
      .or(boolLiteral())
      .or(nullLiteral())
      .cast<Expression>();

  Parser<Expression> numericLiteral() =>
      digit()
          .plus()
          .flatten()
          .mapWithPosition((value, start, end) => Literal(int.parse(value), value)
        ..start = start
        ..end = end);

  Parser<Expression> stringLiteral() =>
      (char('"') & pattern('^"').star().flatten() & char('"'))
          .pick(1)
          .mapWithPosition((value, start, end) => Literal(value, '"$value"')
        ..start = start
        ..end = end);

  Parser<Expression> boolLiteral() =>
      (string('true').or(string('false')))
          .mapWithPosition((value, start, end) => Literal(value == 'true', value)
        ..start = start
        ..end = end);

  Parser<Expression> nullLiteral() =>
      string('null')
          .mapWithPosition((value, start, end) => Literal(null, 'null')
        ..start = start
        ..end = end);

  Parser<Expression> unaryExpression() {
    final ops = ['-', '+', '!', '~'];
    return ops
        .map(string)
        .reduce((a, b) => a.or(b).cast<String>())
        .trim()
        .seq(token)
        .mapWithPosition((list, start, end) {
      final expr = UnaryExpression(list[0], list[1])
        ..start = start
        ..end = end;
      return expr;
    });
  }

  Parser<Expression> variable() =>
      groupOrIdentifier()
          .seq(
        (memberArgument().or(indexArgument()).or(callArgument())).star(),
      )
          .mapWithPosition((list, start, end) {
        Expression obj = list[0];
        final args = list[1] as List;
        for (var arg in args) {
          if (arg is Identifier) obj = MemberExpression(obj, arg);
          else if (arg is Expression) obj = IndexExpression(obj, arg);
          else if (arg is List<Expression>) obj = CallExpression(obj, arg);
        }
        obj.start = start;
        obj.end = end;
        return obj;
      });

  Parser<Expression> group() =>
      (char('(').trim() & expression.trim() & char(')').trim()).pick(1).cast<Expression>();

  Parser<Expression> groupOrIdentifier() =>
      group()
          .or(thisExpression())
          .or(identifier().map((v) => Variable(v)))
          .cast();

  Parser<Identifier> identifier() =>
      (letter() & (word() | char(r'$')).star()).flatten().mapWithPosition((value, start, end) {
        final id = Identifier(value);
        id.start = start;
        id.end = end;
        return id;
      });

  Parser<Identifier> memberArgument() =>
      (char('.') & identifier()).pick(1).cast<Identifier>();

  Parser<Expression> indexArgument() =>
      (char('[') & expression.trim() & char(']')).pick(1).cast<Expression>();

  Parser<List<Expression>> callArgument() =>
      (char('(') &
      arguments.trim() &
      char(')'))
          .pick(1)
          .cast<List<Expression>>();

  Parser<Expression> thisExpression() =>
      string('this').mapWithPosition((value, start, end) {
        final thisExpr = ThisExpression();
        thisExpr.start = start;
        thisExpr.end = end;
        return thisExpr;
      });

  Parser<List<Expression>> get arguments =>
      expression
          .plusSeparated(char(',').trim())
          .map((sl) => sl.elements)
          .optionalWith([])
          .cast<List<Expression>>();

  Parser<List<Expression>> conditionArguments() =>
      (char('?') & expression.trim() & char(':') & expression)
          .pick(1)
          .seq(expression)
          .mapWithPosition((list, start, end) => [list[0], list[1]]);

  Parser<Expression> binaryExpression() =>
      token
          .plusSeparated(binaryOperation())
          .map((sl) {
        final elements = sl.elements;
        Expression left = elements[0];
        for (int i = 1; i < elements.length; i += 2) {
          final op = elements[i] as String;
          final right = elements[i + 1] as Expression;
          left = BinaryExpression(op, left, right);
        }
        return left;
      });

  Parser<String> binaryOperation() =>
      ['+', '-', '*', '/', '%', '==', '!=', '<', '>', '<=', '>=']
          .map(string)
          .reduce((a, b) => a.or(b).cast<String>())
          .trim();
}


/// =======================
/// Main
/// =======================
void main() {
  final parser = ExpressionParser();
  final input = 'inner.doubleValue()';
  final result = parser.expression.parse(input);

  if (result is Success<Expression>) {
    final expr = result.value;
    print('Parsed: $expr');
    final inferencer = TypeInferencer(rootClass);
    final type = expr.accept(inferencer);
    print('Inferred type: ${type.name}');
  }
  else {
    print('Parse error at position ${result.position}');
  }
}
