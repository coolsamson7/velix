import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "text", group: "Widgets")
@JsonSerializable(discriminator: "text")
class TextWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;

  // constructor

  TextWidgetData({required this.label, super.type = "text"});
}