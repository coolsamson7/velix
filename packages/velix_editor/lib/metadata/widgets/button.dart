import 'package:flutter/material.dart' hide Padding;
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/property_panel/editor/code_editor.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../validate/validate.dart';
import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "button", group: "widgets", icon: "widget_button")
@JsonSerializable(discriminator: "button", includeNull: false)
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  Value label;
  @DeclareProperty(group: "font")
  Font? font;
  @DeclareProperty(group: "style")
  Color? foregroundColor;
  @DeclareProperty(group: "style")
  Color? backgroundColor;
  @DeclareProperty(group: "layout")
  Insets? padding;
  @DeclareProperty(group: "events", editor: CodeEditorBuilder, validator: ExpressionPropertyValidator)
  String? onClick;

  // constructor

  ButtonWidgetData({super.type = "button", super.cell, super.children, required this.label, this.font, this.foregroundColor, this.backgroundColor, this.padding, this.onClick});
}