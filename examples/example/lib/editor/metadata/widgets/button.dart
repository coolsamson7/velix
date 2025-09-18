import 'package:velix/reflectable/reflectable.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "button", group: "Widgets")
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;

  // constructor

  ButtonWidgetData({required this.label, super.type = "button"});
}