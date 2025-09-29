import 'package:flutter/material.dart' hide WidgetBuilder, Padding, Page;
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../../actions/action_evaluator.dart';
import '../../actions/eval.dart';
import '../../metadata/widgets/button.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class ButtonWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // instance data

  ActionCompiler compiler = ActionCompiler();

  // constructor

  ButtonWidgetBuilder() : super(name: "button");

  // internal

  Call compile(String input, TypeDescriptor context) {
    return compiler.compile(input, context: context);
  }

  VoidCallback? onClick(ButtonWidgetData data, Environment environment, BuildContext context) { // TODO cache!
    if (data.onClick != null) {
      var instance = Provider.of<WidgetContext>(context).page;
      var type = TypeDescriptor.forType(instance.runtimeType);

      return () => compile(data.onClick!,type).eval(instance);
    }

    return null;
  }

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment, BuildContext context) {
    return ElevatedButton(
      onPressed: onClick(data, environment, context),
      style: ElevatedButton.styleFrom(
          textStyle: textStyle(data.font),
          padding: edgeInsets(data.padding)
      ),
      child: Text(data.label),
    );
  }
}

@Injectable()
class ButtonEditWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonEditWidgetBuilder() : super(name: "button", edit: true);

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment, BuildContext context) {
    // In edit mode, make the button non-interactive
    return IgnorePointer(
      ignoring: true,
      child: ElevatedButton(
        onPressed: () {  }, // This won't be called due to IgnorePointer
        style: ElevatedButton.styleFrom(
          textStyle: textStyle(data.font),
          padding: edgeInsets(data.padding)
        ),
        child: Text(data.label),
      ),
    );
  }
}