import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../metadata/widgets/button.dart';
import '../widget_builder.dart';

@Injectable()
class ButtonWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  ButtonWidgetBuilder() : super(name: "button");

  @override
  Widget create(ButtonWidgetData data) {
    return ElevatedButton(
      onPressed: () {  }, // TODO
      child: Text(data.label),
    );
  }
}

@Injectable()
class ButtonEditWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  ButtonEditWidgetBuilder() : super(name: "button", edit: true);

  @override
  Widget create(ButtonWidgetData data) {
    return ElevatedButton(
      onPressed: () {  }, // TODO
      child: Text(data.label),
    );
  }
}
