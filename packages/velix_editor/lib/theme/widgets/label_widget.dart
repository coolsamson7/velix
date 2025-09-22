import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../metadata/widgets/label.dart';
import '../widget_builder.dart';

@Injectable()
class LabelWidgetBuilder extends WidgetBuilder<LabelWidgetData> {
  LabelWidgetBuilder() : super(name: "label");

  @override
  Widget create(LabelWidgetData data, Environment environment) {
    return Text(data.label,
        style: textStyle(data.font)
    );
  }
}

@Injectable()
class EditLabelWidgetBuilder extends WidgetBuilder<LabelWidgetData> {
  EditLabelWidgetBuilder() : super(name: "label", edit: true);

  @override
  Widget create(LabelWidgetData data, Environment environment) {
    // In edit mode, make the text field non-interactive
    return IgnorePointer(
      ignoring: true,
      child: Text(data.label,
          style: textStyle(data.font) // TODO more...
      ),
    );
  }
}