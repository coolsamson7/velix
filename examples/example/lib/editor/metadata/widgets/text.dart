import 'package:velix/reflectable/reflectable.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "text", group: "Widgets")
class TextWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;

  // constructor

  TextWidgetData({required this.label, super.type = "text"});
}