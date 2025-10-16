import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../../metadata/widgets/label.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class
LabelWidgetBuilder extends WidgetBuilder<LabelWidgetData> {
  // constructor

  LabelWidgetBuilder() : super(name: "label");

  // override

  @override
  Widget create(LabelWidgetData data, Environment environment, BuildContext context) {
    var widgetContext =  WidgetContextScope.of(context);

    var (label, typeProperty) = resolveValue(widgetContext, data.label);

    var result = Text(label,
        style: data.font?.textStyle(color: data.color, backgroundColor: data.backgroundColor)
    );

    if (data.label.type == ValueType.binding) {
        widgetContext.addBinding(typeProperty!, data);
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