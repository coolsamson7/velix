
import 'package:flutter/material.dart' hide Theme;
import 'package:velix_di/di/di.dart';

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

  // abstract

  Widget create(T data, Environment environment);
}

