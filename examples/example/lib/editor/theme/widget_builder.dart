
import 'package:flutter/material.dart' hide Theme;
import 'package:sample/editor/theme/theme.dart';
import 'package:velix_di/di/di.dart';

import '../metadata/widget_data.dart';

@Injectable(factory: false, eager: false) // TODO
abstract class WidgetBuilder<T extends WidgetData> {
  // instance data

  String name;

  // constructor

  WidgetBuilder({required this.name});

  // lifecycle

  @Inject()
  void setThema(Theme theme) {
    theme.register(this, name);
  }
  // abstract

  Widget create(T data);
}

