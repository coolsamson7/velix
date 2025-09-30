import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../property_panel/editor/code_editor.dart';
import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "label", group: "widgets", icon: "widget_label")
@JsonSerializable(discriminator: "label", includeNull: false)
class LabelWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;
  @DeclareProperty(group: "general")
  Font? font;
  @DeclareProperty(group: "general", editor: CodeEditorBuilder)
  String? databinding;
  @DeclareProperty(group: "general")
  Value? value;

  // constructor

  LabelWidgetData({super.type = "text", super.children = const [], required this.label, this.value, this.font, this.databinding});
}