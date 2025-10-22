import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../property_panel/editor/code_editor.dart';
import '../../validate/validate.dart';
import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "dropdown", group: "widgets", icon: "widget_switch")
@JsonSerializable(discriminator: "dropdown", includeNull: false)
class DropDownWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "style")
  Insets? padding;
  @DeclareProperty(group: "general")
  Value placeholder;
  @DeclareProperty(group: "data")
  String? databinding;
  @DeclareProperty(group: "events", editor: CodeEditorBuilder, validator: ExpressionPropertyValidator)
  String? onSelect;

  // constructor

  DropDownWidgetData({super.type = "dropdown", super.cell, super.children, this.padding, this.onSelect, this.databinding, required this.placeholder});
}