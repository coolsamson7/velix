import 'package:flutter/material.dart' hide WidgetBuilder, Padding;
import 'package:velix_di/di/di.dart';

import '../../metadata/properties/properties.dart';
import '../../metadata/widgets/button.dart';
import '../widget_builder.dart';

@Injectable()
class ButtonWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonWidgetBuilder() : super(name: "button");

  // internal

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment) {
    return ElevatedButton(
      onPressed: () {  }, // TODO
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