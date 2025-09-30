import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../property_panel/editor/code_editor.dart';
import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "switch", group: "widgets", icon: "widget_switch")
@JsonSerializable(discriminator: "switch", includeNull: false)
class SwitchWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;
  @DeclareProperty(group: "general", editor: CodeEditorBuilder)
  String? databinding;

  // constructor

  SwitchWidgetData({super.type = "switch", super.children = const [], required this.label, this.databinding});
}