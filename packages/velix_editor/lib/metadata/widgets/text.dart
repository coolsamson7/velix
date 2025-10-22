import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../property_panel/editor/code_editor.dart';
import '../../validate/validate.dart';
import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "text", group: "widgets", icon: "widget_text")
@JsonSerializable(discriminator: "text", includeNull: false)
class TextWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  Value label;
  @DeclareProperty(group: "data", editor: CodeEditorBuilder, validator: ExpressionPropertyValidator)
  String? databinding;

  // constructor

  TextWidgetData({super.type = "text", super.cell, super.children, required this.label, required this.databinding});
}