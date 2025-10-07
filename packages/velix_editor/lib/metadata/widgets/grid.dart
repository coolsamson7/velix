import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
enum GridSizeMode { fixed, flex, auto } // "auto" = wrap content

@Dataclass()
enum GridAlignment { start, center, end, stretch }

@Dataclass()
class GridRow {
  // instance data

  @DeclareProperty()
  GridSizeMode sizeMode;
  @DeclareProperty()
  double size;
  @DeclareProperty()
  GridAlignment alignment;

  // constructor

  GridRow({
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
  int rows;
  @DeclareProperty(group: "layout")
  int cols;
  @DeclareProperty(group: "layout")
  int spacing;
  @DeclareProperty(group: "layout")
  List<GridRow> gridRows;

  // constructor

  GridWidgetData({super.type = "grid", super.children, super.cell, this.rows = 1, this.cols = 1, this.spacing = 0, List<GridRow>? gridRows}): gridRows = gridRows ?? <GridRow>[];

  // override

  @override
  bool acceptsChild(WidgetData widget) {
    return !isParentOf(widget, this);
  }
}
