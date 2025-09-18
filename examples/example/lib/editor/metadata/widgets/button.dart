import 'package:velix/reflectable/reflectable.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "button", group: "Widgets")
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;
  @DeclareProperty(group: "Group1")
  int number;
  @DeclareProperty(group: "Group2")
  bool isCool;

  // constructor

  ButtonWidgetData({required this.label, required this.number, required this.isCool, super.type = "button"});
}