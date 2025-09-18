
import 'package:sample/editor/theme/widget_builder.dart';
import 'package:velix_di/di/di.dart';

@Injectable()
class Theme {
  // instance data

  Map<String, WidgetBuilder> widgets = {};

  // constructor

  // public

  void register(WidgetBuilder builder, String name) {
    widgets[name] = builder;
  }

  WidgetBuilder operator [](String type) {
    return widgets[type]!;
  }
}