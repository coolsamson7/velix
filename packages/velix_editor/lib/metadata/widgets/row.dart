import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "row", group: "container", icon: Icons.view_column)
@JsonSerializable(discriminator: "row", includeNull: false)
class RowWidgetData extends WidgetData {
  // instance data

  // constructor

  RowWidgetData({super.type = "row", super.children = const []});

  // override

  @override
  bool acceptsChild(WidgetData widget) { // TODO parent -> child
    return widget.parent != this;
  }
}
