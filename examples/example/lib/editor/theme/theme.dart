
import 'package:sample/editor/theme/widget_builder.dart';
import 'package:velix_di/di/di.dart';

@Injectable()
class Theme {
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