

import 'package:velix_di/di/di.dart';

import 'widget_builder.dart';

@Injectable()
class WidgetFactory {
  // instance data

  Map<String, WidgetBuilder> widgets = {};
  Map<String, WidgetBuilder> editWidgets = {};

  // constructor

  // public

  void register(WidgetBuilder builder, String name, bool edit) {
    if (edit)
      editWidgets[name] = builder;
    else
      widgets[name] = builder;
  }

  WidgetBuilder builder(String type, {bool edit = false}) {
    return edit ? editWidgets[type]! : widgets[type]!;
  }
}