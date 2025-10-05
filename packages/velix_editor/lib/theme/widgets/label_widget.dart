import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_ui/databinding/valued_widget.dart';

import '../../metadata/widgets/label.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class LabelWidgetBuilder extends WidgetBuilder<LabelWidgetData> {
  // constructor

  LabelWidgetBuilder() : super(name: "label");

  // internal

  // override

  @override
  Widget create(LabelWidgetData data, Environment environment, BuildContext context) {
    var widgetContext = Provider.of<WidgetContext>(context);

    var mapper = widgetContext.formMapper;
    var instance = widgetContext.page;

    var adapter = ValuedWidget.getAdapter("label");

    var label = data.label.value;

    var result = Text(label,
        style: data.font?.textStyle(color: data.color, backgroundColor: data.backgroundColor)
    );

    switch (data.label.type) {
      case ValueType.i18n:
        label = label.tr();
        break;
      case ValueType.binding:
        widgetContext.addBinding(label, data);
        var typeProperty = mapper.computeProperty(TypeDescriptor.forType(instance.runtimeType), label);
        mapper.map(property: typeProperty, widget: result, adapter: adapter);
        break;
      case ValueType.value:
        break;
    }

    return result;
  }
}

@Injectable()
class EditLabelWidgetBuilder extends WidgetBuilder<LabelWidgetData> {
  // constructor

  EditLabelWidgetBuilder() : super(name: "label", edit: true);

  // override

  @override
  Widget create(LabelWidgetData data, Environment environment, BuildContext context) {
    var label = data.label.value;
    switch (data.label.type) {
      case ValueType.i18n:
        label = label.tr();
        break;
      case ValueType.binding:
        //widgetContext.addBinding(label, data);
        break;
      case ValueType.value:
        break;
    }


    return IgnorePointer(
      ignoring: true,
      child: Text(label,
          style: data.font?.textStyle()
      ),
    );
  }
}