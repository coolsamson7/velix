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

  @override
  bool acceptsChild(WidgetData widget) {
    return !isParentOf(widget, this);
  }
}
