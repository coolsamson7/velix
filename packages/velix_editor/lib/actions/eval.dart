

// will generate a call structure

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_editor/actions/visitor.dart';

import 'expressions.dart';

class CallVisitorContext extends VisitorContext {
  // instance data

  final dynamic instance;
  final Map<String,Eval Function(String)> contextVars;

  // constructor

  CallVisitorContext({required this.instance, Map<String,Eval Function(String)>? contextVars}) :contextVars = contextVars ?? {};
}

class EvalContext {
  dynamic instance;
  Map<String,dynamic> variables = {};

  EvalContext({required this.instance, required this.variables});

  dynamic get(String name) {
    return variables[name];
  }
}

abstract class Eval {
  dynamic eval(dynamic value, EvalContext context);
}

class This extends Eval {
  @override
  dynamic eval(dynamic value, EvalContext context) {
    return value;
  }
}

class EvalValue extends Eval {
  // instance data

  dynamic value;

  // constructor

  EvalValue({required this.value});

  // override

  @override
  dynamic eval(dynamic value, EvalContext context) {
    return this.value;
  }
}

class EvalContextVar extends Eval {
  // instance data

  final String variable;

  // constructor

  EvalContextVar({required this.variable});

  // override

  @override
  dynamic eval(dynamic value, EvalContext context) {
    return context.get(variable);
  }
}

class EvalUnary extends Eval {
  final String op;
  final Eval argument;

  EvalUnary({required this.op, required this.argument});

  @override
  dynamic eval(dynamic value, EvalContext context) {
    final arg = argument.eval(value, context);
    switch (op) {
      case '-': return -arg;
      case '!': return !arg;
      case '~': return ~arg;
      default: return arg;
    }
  }
}

class EvalBinary extends Eval {
  final String op;
  final Eval left;
  final Eval right;

  EvalBinary({required this.op, required this.left, required this.right});

  @override
  dynamic eval(dynamic value, EvalContext context) {
    final l = left.eval(value, context);
    final r = right.eval(value, context);

    switch (op) {
      case '+':  return l + r;
      case '-':  return l - r;
      case '*':  return l * r;
      case '/':  return l / r;
      case '%':  return l % r;
      case '&&': return l && r;
      case '||': return l || r;
      case '==': return l == r;
      case '!=': return l != r;
      case '<':  return l < r;
      case '<=': return l <= r;
      case '>':  return l > r;
      case '>=': return l >= r;
      default: return l;
    }
  }
}

class EvalConditional extends Eval {
  final Eval test;
  final Eval consequent;
  final Eval alternate;

  EvalConditional({required this.test, required this.consequent, required this.alternate});

  @override
  dynamic eval(dynamic value, EvalContext context) {
    return test.eval(value, context)
        ? consequent.eval(value, context)
        : alternate.eval(value, context);
  }
}

class EvalIndex extends Eval {
  final Eval object;
  final Eval index;

  EvalIndex({required this.object, required this.index});

  @override
  dynamic eval(dynamic value, EvalContext context) {
    final obj = object.eval(value, context);
    final idx = index.eval(value, context);
    return obj[idx];
  }
}

class EvalField extends Eval {
  // instance data

  FieldDescriptor field;

  // constructor

  EvalField({required this.field});

  // override

  @override
  dynamic eval(dynamic value, EvalContext context) {
    return field.get(value);
  }
}

class EvalMember extends Eval {
  // instance data

  Eval receiver;
  FieldDescriptor field;

  // constructor

  EvalMember({required this.receiver, required this.field});

  // override

  @override
  dynamic eval(dynamic value, EvalContext context) {
    return field.get(receiver.eval(value, context));
  }
}

class EvalMethod extends Eval {
  // instance data

  Eval receiver;
  MethodDescriptor method;
  late List<Eval> arguments;

  // constructor

  EvalMethod({required this.receiver, required this.method});

  // override

  @override
  dynamic eval(dynamic value, EvalContext context) {
    var args = arguments.map((arg) => arg.eval(value, context));

    return method.invoker!([receiver.eval(value, context), ...args]);
  }
}

class EvalVisitor extends ExpressionVisitor<Eval,CallVisitorContext> {
  // instance data

  final TypeDescriptor rootClass;

  // constructor

  EvalVisitor(this.rootClass);

  // visitors

  @override
  Eval visitLiteral(Literal expr, CallVisitorContext context) {
    return EvalValue(value: expr.value);
  }

  @override
  Eval visitVariable(Variable expr, CallVisitorContext context) {
    if ( context.contextVars.containsKey(expr.identifier.name)) {
      return EvalContextVar(variable: expr.identifier.name);
    }

    var property =  rootClass.getProperty(expr.identifier.name);
    return property.isField() ?
      EvalField(field: property as FieldDescriptor) :
      EvalMethod(receiver: This(), method: property as MethodDescriptor); // ?context.instance must be a call
  }

  @override
  Eval visitUnary(UnaryExpression expr, CallVisitorContext context) {
    return EvalUnary(op: expr.op, argument: expr.argument.accept(this, context));
  }


  @override
  Eval visitBinary(BinaryExpression expr, CallVisitorContext context) {
    return EvalBinary(
      op: expr.op,
      left: expr.left.accept(this, context),
      right: expr.right.accept(this, context),
    );
  }

  @override
  Eval visitConditional(ConditionalExpression expr, CallVisitorContext context) {
    return EvalConditional(
      test: expr.test.accept(this, context),
      consequent: expr.consequent.accept(this, context),
      alternate: expr.alternate.accept(this, context),
    );
  }

  @override
  Eval visitIndex(IndexExpression expr, CallVisitorContext context) {
    return EvalIndex(
      object: expr.object.accept(this, context),
      index: expr.index.accept(this, context),
    );
  }

  @override
  Eval visitMember(MemberExpression expr, CallVisitorContext context) {
    var receiver = expr.object.accept(this, context);
    var type = expr.object.getType<ObjectType>();

    var property =  expr.property.name;
    var descriptor = type.typeDescriptor.getProperty<AbstractPropertyDescriptor>(property);

    return descriptor.isField() ?
      EvalMember(receiver: receiver, field: descriptor as FieldDescriptor) :
      EvalMethod(receiver: receiver, method: descriptor as MethodDescriptor);
  }

  @override
  Eval visitThis(ThisExpression expr, CallVisitorContext context) {
    return This();
  }

  @override
  Eval visitCall(CallExpression expr, CallVisitorContext context) {
    var method = expr.callee.accept(this, context) as EvalMethod;

    method.arguments = expr.arguments.map((arg) => arg.accept(this, context)).toList();

    return method;
  }
}