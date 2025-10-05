import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "grid", group: "container", icon: "widget_grid")
@JsonSerializable(discriminator: "grid", includeNull: false)
class GridWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "layout")
  int rows;
  @DeclareProperty(group: "layout")
  int cols;
  @DeclareProperty(group: "layout")
  int spacing;

  // constructor

  GridWidgetData({super.type = "grid", super.children = const [], super.cell, this.rows = 1, this.cols = 1, this.spacing = 0});

  // override

  // accept if widget is not a parent of this or thsi is a child of widget

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
  bool acceptsChild(WidgetData widget) { // TODO parent -> child, CEll!!!
    return !isParentOf(widget, this); //widget.parent != this;
  }
}
