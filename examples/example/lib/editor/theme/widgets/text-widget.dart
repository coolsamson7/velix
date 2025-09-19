import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../metadata/widgets/text.dart';
import '../widget_builder.dart';

@Injectable()
class TextWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // instance data

  // constructor

  TextWidgetBuilder() : super(name: "text");

  // override

  @override
  Widget create(TextWidgetData data) {
    return TextField(decoration: InputDecoration(labelText: data.label));
  }
}

@Injectable()
class TextEditWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // instance data

  // constructor

  TextEditWidgetBuilder() : super(name: "text", edit: true);

  // override

  @override
  Widget create(TextWidgetData data) {
    return TextField(decoration: InputDecoration(labelText: data.label));
  }
}