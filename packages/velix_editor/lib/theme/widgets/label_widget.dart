import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_ui/databinding/form_mapper.dart';
import 'package:velix_ui/databinding/valued_widget.dart';

import '../../metadata/widgets/label.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class LabelWidgetBuilder extends WidgetBuilder<LabelWidgetData> {
  // constructor

  LabelWidgetBuilder() : super(name: "label");

  // override

  @override
  Widget create(LabelWidgetData data, Environment environment, BuildContext context) {
    var widgetContext = Provider.of<WidgetContext>(context);

    var mapper = widgetContext.formMapper;
    var instance = widgetContext.page;

    var adapter = ValuedWidget.getAdapter("label");

    var typeProperty = mapper.computeProperty(TypeDescriptor.forType(instance.runtimeType), data.databinding!);

    var result = Text(data.label,
        style: textStyle(data.font)
    );

    // TODO: no labeladapter yet

    /*TODO databinding mapper.addListener((event) {
      if (event.path == data.databinding && event.value != result.data ) {
        print("changed");
      }
    })*/;

    mapper.map(property: typeProperty, widget: result, adapter: adapter);

    return result;
  }
}

// TODO: databinding not yet included

class BoundLabel extends StatefulWidget {
  final String? bindingPath;
  final String initialText;
  final TextStyle? style;
  final FormMapper mapper;

  const BoundLabel({
    super.key,
    required this.bindingPath,
    required this.initialText,
    required this.mapper,
    this.style,
  });

  @override
  State<BoundLabel> createState() => _BoundLabelState();
}

class _BoundLabelState extends State<BoundLabel> {
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.initialText;

    widget.mapper.addListener((event) {
      if (event.path == widget.bindingPath && event.value != _text) {
        setState(() {
          _text = event.value?.toString() ?? "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text, style: widget.style);
  }
}


@Injectable()
class EditLabelWidgetBuilder extends WidgetBuilder<LabelWidgetData> {
  // constructor

  EditLabelWidgetBuilder() : super(name: "label", edit: true);

  // override

  @override
  Widget create(LabelWidgetData data, Environment environment, BuildContext context) {
    // In edit mode, make the text field non-interactive
    return IgnorePointer(
      ignoring: true,
      child: Text(data.label,
          style: textStyle(data.font) // TODO more...
      ),
    );
  }
}