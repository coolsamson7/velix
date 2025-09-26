import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/infer_types.dart';

import 'action_parser.dart';
import 'eval.dart';

class ActionCompiler {
  // instance data

  final parser = ActionParser();

  // public

   Call compile(String input, {required TypeDescriptor context}) {
     var expression = parser.parse(input);

     // check types

     final checker = TypeChecker(RuntimeTypeTypeResolver(root: context));

     expression.accept(checker);

     // compute call

     var visitor = CallVisitor(context);

     return expression.accept(visitor);
   }
}

class ActionEvaluator {
  // instance data

  dynamic instance;
  final parser = ActionParser();
  TypeDescriptor contextType;

  // constructor

  ActionEvaluator({required this.contextType});

  // public

  dynamic call(String input, dynamic instance) {
    var expression = parser.parse(input);

    // check types

    final checker = TypeChecker(RuntimeTypeTypeResolver(root: contextType));

    expression.accept(checker);

    // compute call

    var visitor = CallVisitor(contextType);

    var call = expression.accept(visitor);

    // eval

    return call.eval(instance);
  }
}