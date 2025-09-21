import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../metadata/widgets/button.dart';
import '../widget_builder.dart';

@Injectable()
class ButtonWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonWidgetBuilder() : super(name: "button");

  // internal

  TextStyle? textStyle(Font? font) {
    if (font != null)
      return TextStyle(
        fontSize: font.size.toDouble(),
        fontWeight: font.weight,
        fontStyle: font.style,
      );
    else return null;
  }


  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment) {
    return ElevatedButton(
      onPressed: () {  }, // TODO
      style: ElevatedButton.styleFrom(
          textStyle: textStyle(data.font)
        //padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(data.label),
    );
  }
}

@Injectable()
class ButtonEditWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonEditWidgetBuilder() : super(name: "button", edit: true);

  // internal

  TextStyle? textStyle(Font? font) {
    if (font != null)
      return TextStyle(
        fontSize: font.size.toDouble(),
        fontWeight: font.weight,
        fontStyle: font.style,
      );
    else return null;
  }

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment) {
    // In edit mode, make the button non-interactive
    return IgnorePointer(
      ignoring: true,
      child: ElevatedButton(
        onPressed: () {  }, // This won't be called due to IgnorePointer
        style: ElevatedButton.styleFrom(
          textStyle: textStyle(data.font)
          //padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), TODO
        ),
        child: Text(data.label),
      ),
    );
  }
}