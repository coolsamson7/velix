import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "button", group: "Widgets", icon: Icons.text_fields)
@JsonSerializable(discriminator: "button")
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;
  @DeclareProperty(group: "Group1")
  int number;
  @DeclareProperty(group: "Group2")
  bool isCool;

  // constructor

  ButtonWidgetData({required this.label, required this.number, required this.isCool, super.type = "button"});
}