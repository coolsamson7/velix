import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_ui/velix_ui.dart';

import '../../metadata/widgets/text.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class TextWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // constructor

  TextWidgetBuilder() : super(name: "text");

  // override

  @override
  Widget create(TextWidgetData data, Environment environment, BuildContext context) {
    var widgetContext = Provider.of<WidgetContext>(context);

    var mapper = widgetContext.formMapper;
    var instance = widgetContext.page;

    TextEditingController controller =  TextEditingController();
    FocusNode? focusNode = FocusNode();

    // TODO databinding

    var adapter = ValuedWidget.getAdapter("text"); // TODO better: adapterFor<c>

    var typeProperty = mapper.computeProperty(TypeDescriptor.forType(instance.runtimeType), data.databinding!);

    controller.addListener(() {
        mapper.notifyChange(property: typeProperty, value: controller.text);
      });

    TextFormField result = TextFormField(
        key: ValueKey(data.databinding),
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(labelText: data.label)
        //style: args.get<TextStyle>('style'),
        //validator: validate,
        //keyboardType: textInputType,
        //inputFormatters: inputFormatters
    );

    mapper.map(property: typeProperty, widget: result, adapter: adapter);

    return result;
  }
}

@Injectable()
class TextEditWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // constructor

  TextEditWidgetBuilder() : super(name: "text", edit: true);

  // override


  @override
  Widget create(TextWidgetData data, Environment environment, BuildContext context) {
    // In edit mode, make the text field non-interactive
    return IgnorePointer(
      ignoring: true,
      child: TextField(
        decoration: InputDecoration(labelText: data.label),
        // Optional: You might also want to disable the field visually
        enabled: false, // This makes it look disabled but IgnorePointer is what actually blocks interaction
      ),
    );
  }
}