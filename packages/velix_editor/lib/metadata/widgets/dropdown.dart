import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../property_panel/editor/code_editor.dart';
import '../../property_panel/editor/template_editor.dart';
import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "dropdown", group: "widgets", icon: "widget_switch")
@JsonSerializable(discriminator: "dropdown", includeNull: false)
class DropDownWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general", editor: TemplateEditorBuilder)
  WidgetData template;
  @DeclareProperty(group: "style")
  Insets? padding;
  @DeclareProperty(group: "databinding", editor: CodeEditorBuilder)
  String? databinding;

  // constructor

  DropDownWidgetData({super.type = "switch", super.cell, super.children, required this.template, this.padding, this.databinding});
}