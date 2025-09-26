import 'package:flutter/material.dart' hide Padding;
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/property_panel/editor/code_editor.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "button", i18n: "editor:widgets.button.title", group: "widgets", icon: Icons.text_fields)
@JsonSerializable(discriminator: "button")
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(groupI18N: "editor:groups.general", i18n: "editor:widgets.button.label")
  String label;
  @DeclareProperty(group: "Font Properties")
  Font? font;
  @DeclareProperty(group: "Layout Properties")
  Padding? padding;
  @DeclareProperty(group: "General Properties", editor: CodeEditor)
  String? onClick;

  // constructor

  ButtonWidgetData({super.type = "button", super.children = const [], required this.label, this.font, this.padding});
}