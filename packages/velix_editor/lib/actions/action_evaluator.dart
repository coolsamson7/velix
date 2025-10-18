import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/infer_types.dart';

import 'action_parser.dart';
import 'eval.dart';

class ActionCompiler { // TODO: sender???
  ActionCompiler._internal();

  // static singleton instance (initialized on first call)
  static final ActionCompiler _instance = ActionCompiler._internal();

  // public getter
  static ActionCompiler get instance => _instance;


  // instance data

  final parser = ActionParser.instance;

  // public

   Eval compile(String input, {required TypeDescriptor context}) {
     var result = parser.parseStrict(input, typeChecker: TypeChecker(RuntimeTypeTypeResolver(root: context)));

     // compute call

     var visitor = EvalVisitor(context);

     return result.value!.accept(visitor, CallVisitorContext(instance: null));
   }
}

class ActionEvaluator {
  // instance data

  dynamic instance;
  final parser = ActionParser.instance;
  TypeDescriptor contextType;

  // constructor

  ActionEvaluator({required this.contextType});

  // public

  dynamic call(String input, dynamic instance) {
    var result = parser.parseStrict(input, typeChecker: TypeChecker(RuntimeTypeTypeResolver(root: contextType)));

    // compute call

    var visitor = EvalVisitor(contextType);

    var call = result.value!.accept(visitor, CallVisitorContext(instance: instance));

    // eval

    return call.eval(instance);
  }
}