import 'package:flutter/material.dart' hide WidgetBuilder, Padding, Page;
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../../actions/action_evaluator.dart';
import '../../actions/eval.dart';
import '../../metadata/widgets/button.dart';
import '../../property_panel/editor/code_editor.dart';
import '../widget_builder.dart';

@Injectable()
class ButtonWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonWidgetBuilder() : super(name: "button");

  // internal

  Call compile(String input, TypeDescriptor context) {
    return ActionCompiler().compile(input, context: context);
  }

  // TODO: the editor needs a root object!
  VoidCallback? onClick(ButtonWidgetData data, Environment environment) {
    if (data.onClick != null) {
      var instance = environment.get<Page>();

      return () => compile(data.onClick!, TypeDescriptor.forType(Page)).eval(instance);
    }

    return null;
  }

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment) {
    return ElevatedButton(
      onPressed: onClick(data, environment),
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
  Widget create(ButtonWidgetData data, Environment environment) {
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