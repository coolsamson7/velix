
import 'package:flutter/material.dart' hide Padding;
import '../../metadata/properties/properties.dart' as Props;
import 'package:velix_di/di/di.dart';

import '../metadata/widget_data.dart';
import 'theme.dart';

extension InsetsHelper on Props.Insets {
  EdgeInsets edgeInsets() {
    return EdgeInsets.fromLTRB(left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
  }
}

extension FontHelper on Props.Font {
  TextStyle textStyle({Color? color, Color? backgroundColor}) {
      return TextStyle(
        color: color,
        backgroundColor: backgroundColor,
        fontFamily: family,
        fontSize: size.toDouble(),
        fontWeight: weight,
        fontStyle: style,
      );
  }
}

extension BorderHelper on Props.Border {
  Border border() {
    return  Border.all(
        color: color,
        width: width.toDouble(),
        style: BorderStyle.solid
    );
  }
}

@Injectable(factory: false, eager: false)
abstract class WidgetBuilder<T extends WidgetData> {
  // instance data

  String name;
  bool edit;

  // constructor

  WidgetBuilder({required this.name, this.edit = false});

  // lifecycle

  @Inject()
  void setThema(WidgetFactory theme) {
    theme.register(this, name, edit);
  }

  // abstract

  Widget create(T data, Environment environment, BuildContext context);
}

