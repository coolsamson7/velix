import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../metadata/widgets/text.dart';
import '../widget_builder.dart';

@Injectable()
class TextWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  TextWidgetBuilder() : super(name: "text");

  @override
  Widget create(TextWidgetData data, Environment environment, BuildContext context) {
    return TextField(decoration: InputDecoration(labelText: data.label));
  }
}

@Injectable()
class TextEditWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  TextEditWidgetBuilder() : super(name: "text", edit: true);

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