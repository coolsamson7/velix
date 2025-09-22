
import 'package:flutter/material.dart' hide Padding;
import 'package:velix_di/di/di.dart';

import '../metadata/properties/properties.dart';
import '../metadata/widget_data.dart';
import 'theme.dart';

@Injectable(factory: false, eager: false) // TODO
abstract class WidgetBuilder<T extends WidgetData> {
  // instance data

  String name;
  bool edit;

  // constructor

  WidgetBuilder({required this.name, bool edit = false}) : edit = edit;

  // lifecycle

  @Inject()
  void setThema(WidgetFactory theme) {
    theme.register(this, name, edit);
  }

  // common functions

  TextStyle? textStyle(Font? font) {
    if (font != null)
      return TextStyle(
        fontSize: font.size.toDouble(),
        fontWeight: font.weight,
        fontStyle: font.style,
      );
    else return null;
  }

  EdgeInsets? edgeInsets(Padding? padding) {
    if ( padding != null)
      return EdgeInsets.only(
        left: padding.left.toDouble(),
        top: padding.top.toDouble(),
        right: padding.right.toDouble(),
        bottom: padding.bottom.toDouble(),
      );
    else return null;
  }


  // abstract

  Widget create(T data, Environment environment);
}

