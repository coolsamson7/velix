import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../property_panel/editor/code_editor.dart';
import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "text", group: "widgets", icon: Icons.text_fields)
@JsonSerializable(discriminator: "text", includeNull: false)
class TextWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;
  @DeclareProperty(group: "general", editor: CodeEditorBuilder)
  String? databinding;

  // constructor

  TextWidgetData({super.type = "text", super.children = const [], required this.label, required this.databinding});
}