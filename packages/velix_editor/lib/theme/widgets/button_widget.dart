import 'package:flutter/material.dart' hide WidgetBuilder, Padding, Page;
import 'package:velix_di/di/di.dart';

import '../../actions/action_evaluator.dart';
import '../../actions/eval.dart';
import '../../metadata/properties/properties.dart';
import '../../metadata/widgets/button.dart';
import '../../widget_container.dart';
import '../abstract_widget.dart' show AbstractEditorWidgetState;
import '../widget_builder.dart';

@Injectable()
class ButtonWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonWidgetBuilder() : super(name: "button");

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment, BuildContext context) {
    return ButtonWidget(data: data, key: ValueKey(data.id));
  }
}

// A stateful wrapper around ElevatedButton that caches the compiled call
class ButtonWidget extends StatefulWidget {
  // instance data

  final ButtonWidgetData data;

  const ButtonWidget({super.key, required this.data});

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends AbstractEditorWidgetState<ButtonWidget> {
  VoidCallback? _onClick;

  @override
  String extractId(Object widget) {
    return (this.widget as ValueKey<String>).value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only compile once per lifecycle if onClick is set
    if (widget.data.onClick != null && widget.data.onClick!.isNotEmpty && _onClick == null) {
      var widgetContext = WidgetContextScope.of(context);

      final call = ActionCompiler.instance.compile(widget.data.onClick!, context: widgetContext.typeDescriptor);
      _onClick = () => call.eval(widgetContext.instance, EvalContext(instance: widgetContext.instance, variables: {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    var widgetContext =  WidgetContextScope.of(context);

    var (label, typeProperty) = resolveValue(widgetContext, widget.data.label);

    var result = ElevatedButton(
      onPressed: _onClick,
      style: ElevatedButton.styleFrom(
        //shape: ,
        textStyle: widget.data.font?.textStyle(),
        foregroundColor: widget.data.foregroundColor,
        backgroundColor: widget.data.backgroundColor,
        padding: widget.data.padding?.edgeInsets(),
      ),
      child: Text(label),
    );

    if (widget.data.label.type == ValueType.binding) {
      widgetContext.addBinding(typeProperty!, widget.data);
    }

    return result;
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
            foregroundColor: data.foregroundColor,
            backgroundColor: data.backgroundColor,
            textStyle: data.font?.textStyle(),
            padding: data.padding?.edgeInsets()
        ),
        child: Text(data.label.value),
      ),
    );
  }
}