import 'package:expressions/expressions.dart';
import 'package:velix/reflectable/reflectable.dart';

class MethodCall {
  // instance data

  final dynamic instance;
  final MethodDescriptor method;

  // constructor

  MethodCall({required this.instance, required this.method});

  // public

  dynamic call(List<dynamic> args) {
    return method.invoker!([instance, ...args]);
  }
}

class ActionEvaluator extends ExpressionEvaluator {
  // instance data

  dynamic instance;
  TypeDescriptor contextType;

  // constructor

  ActionEvaluator({required this.instance}) : contextType = TypeDescriptor.forType(instance.runtimeType);

  // override

  @override
  dynamic evalCallExpression(CallExpression expression, Map<String, dynamic> context) {
    var methodCall = eval(expression.callee, context) as MethodCall;

    return methodCall.call( expression.arguments.map((e) => eval(e, context)).toList());
  }

  @override
  dynamic evalVariable(Variable variable, Map<String, dynamic> context) {
    return contextType.getField(variable.identifier.name).get(instance);
  }

  @override
  dynamic evalMemberExpression(MemberExpression expression, Map<String, dynamic> context) {
    var name = expression.property.name;
    var object = eval(expression.object, context);

    var type = TypeDescriptor.forType(object.runtimeType);
    
    if ( type.hasField(name))
      return type.get(object, name);
    else if (type.hasMethod(name)){
      var method = type.getMethod(name);

      return MethodCall(instance: object, method: method);
    }
  }

  // public

  dynamic call(Expression expression) {
    final context = <String, dynamic>{};

    return eval(expression, context);
  }
}