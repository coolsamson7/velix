import 'package:flutter/material.dart' hide Padding;
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/property_panel/editor/code_editor.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "button", group: "widgets", icon: Icons.text_fields)
@JsonSerializable(discriminator: "button", includeNull: false)
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;
  @DeclareProperty(group: "font")
  Font? font;
  @DeclareProperty(group: "font")
  Color? color;
  @DeclareProperty(group: "layout")
  Insets? padding;
  @DeclareProperty(group: "events", editor: CodeEditorBuilder)
  String? onClick;

  // constructor

  ButtonWidgetData({super.type = "button", super.children = const [], required this.label, this.font, this.color, this.padding, this.onClick});
}