import 'dart:ui';

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';

/// data class for a label
@Dataclass()
@DeclareWidget(name: "label", group: "widgets", icon: "widget_label")
@JsonSerializable(discriminator: "label", includeNull: false)
class LabelWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  Value label;
  @DeclareProperty(group: "style")
  Font? font;
  @DeclareProperty(group: "style")
  Color? color;
  @DeclareProperty(group: "style")
  Color? backgroundColor;

  // constructor

  LabelWidgetData({super.type = "label", super.cell, super.children, required this.label, this.color, this.backgroundColor, this.font});
}