import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
enum GridSizeMode { fixed, flex, auto } // "auto" = wrap content

@Dataclass()
enum GridAlignment { start, center, end, stretch }

@Dataclass()
class GridItem {
  // instance data

  @DeclareProperty()
  GridSizeMode sizeMode;
  @DeclareProperty()
  double size;
  @DeclareProperty()
  GridAlignment alignment;

  // constructor

  GridItem({
    this.sizeMode = GridSizeMode.auto,
    this.size = 1,
    this.alignment = GridAlignment.start,
  });
}

@Dataclass()
@DeclareWidget(name: "grid", group: "container", icon: "widget_grid")
@JsonSerializable(discriminator: "grid", includeNull: false)
class GridWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "layout")
  List<GridItem> rows;
  @DeclareProperty(group: "layout")
  List<GridItem> cols;
  @DeclareProperty(group: "layout")
  int spacing;

  // constructor

  GridWidgetData({super.type = "grid", super.children, super.cell, List<GridItem>? rows, List<GridItem>? cols, this.spacing = 0})
      : rows = rows ?? <GridItem>[], cols = cols ?? <GridItem>[];

  // override

  @override
  bool acceptsChild(WidgetData widget) {
    return !isParentOf(widget, this);
  }
}
