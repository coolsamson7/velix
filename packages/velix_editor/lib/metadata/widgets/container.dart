import 'dart:ui';

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "container", group: "container", icon: "widget_container")
@JsonSerializable(discriminator: "container", includeNull: false)
class ContainerWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "style")
  Border? border;
  @DeclareProperty(group: "style")
  Color? color;
  @DeclareProperty(group: "layout")
  Insets? padding;
  @DeclareProperty(group: "layout")
  Insets? margin;

  // constructor

  ContainerWidgetData({super.type = "container", super.cell, this.border, this.margin, this.padding, this.color, super.children = const []});

  // override

  bool isParentOf(WidgetData w1, WidgetData w2) {
    WidgetData? w = w2.parent;
    while ( w != null) {
      if (w == w1)
        return true;
      w = w.parent;
    }

    return false;
  }

  @override
  bool acceptsChild(WidgetData widget) {
    return !isParentOf(widget, this);
  }
}
