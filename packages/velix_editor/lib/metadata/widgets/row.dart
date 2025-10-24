import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';

/// data class for a row
@Dataclass()
@DeclareWidget(name: "row", group: "container", icon: "widget_row")
@JsonSerializable(discriminator: "row", includeNull: false)
class RowWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "layout")
  MainAxisAlignment? mainAxisAlignment;
  @DeclareProperty(group: "layout")
  CrossAxisAlignment? crossAxisAlignment;
  @DeclareProperty(group: "layout")
  MainAxisSize? mainAxisSize;

  // constructor

  RowWidgetData({this.mainAxisAlignment = MainAxisAlignment.start, this.crossAxisAlignment = CrossAxisAlignment.start, this.mainAxisSize = MainAxisSize.min, super.type = "row", super.children, super.cell});

  // override

  @override
  bool acceptsChild(WidgetData widget) {
    return !isParentOf(widget, this);
  }

  @override
  bool canMoveChild(WidgetData child, Direction direction) {
    switch (direction) {
      case Direction.left:
        return child.index() > 0;

      case Direction.right:
        return child.index() < children.length - 1;

      case Direction.up:
      case Direction.down:
        return false;
    }
  }
}
