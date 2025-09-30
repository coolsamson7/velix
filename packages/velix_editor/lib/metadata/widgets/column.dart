import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "column", group: "container", icon: Icons.view_column)
@JsonSerializable(discriminator: "column", includeNull: false)
class ColumnWidgetData extends WidgetData {
  // instance data

  // constructor

  ColumnWidgetData({super.type = "column", super.children = const []});

  // override

  @override
  bool acceptsChild(WidgetData widget) { // TODO parent -> child
    return widget.parent != this;
  }
}
