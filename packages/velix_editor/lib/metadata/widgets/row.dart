import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


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

  RowWidgetData({this.mainAxisAlignment = MainAxisAlignment.start, this.crossAxisAlignment = CrossAxisAlignment.start, this.mainAxisSize = MainAxisSize.min, super.type = "row", super.children = const []});

  // override

  @override
  bool acceptsChild(WidgetData widget) { // TODO parent -> child
    return widget.parent != this;
  }
}
