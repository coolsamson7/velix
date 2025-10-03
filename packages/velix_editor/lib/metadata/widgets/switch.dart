import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
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
  @DeclareProperty(group: "style")
  Insets? padding;
  @DeclareProperty(group: "databinding", editor: CodeEditorBuilder)
  String? databinding;

  // constructor

  SwitchWidgetData({super.type = "switch", super.cell, super.children = const [], required this.label, this.padding, this.databinding});
}