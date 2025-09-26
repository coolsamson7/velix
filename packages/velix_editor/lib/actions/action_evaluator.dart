import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/infer_types.dart';

import 'action_parser.dart';
import 'eval.dart';


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

    final inferencer = TypeInferencer(RuntimeTypeTypeResolver(root: contextType));
    final type = expression.accept(inferencer);

    print(type);

    // compute call

    var visitor = CallVisitor(contextType);

    var call = expression.accept(visitor);

    // eval

    return call.eval(instance);
  }
}