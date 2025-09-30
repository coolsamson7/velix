import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "grid", group: "container", icon: Icons.view_column)
@JsonSerializable(discriminator: "grid", includeNull: false)
class GridWidgetData extends WidgetData {
  // instance data

  // constructor

  GridWidgetData({super.type = "grid", super.children = const []});

  // override

  @override
  bool acceptsChild(WidgetData widget) { // TODO parent -> child
    return widget.parent != this;
  }
}
