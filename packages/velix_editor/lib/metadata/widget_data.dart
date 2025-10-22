
import 'package:uuid/uuid.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/annotations.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../theme/abstract_widget.dart';

@Dataclass()
class Cell {
  @DeclareProperty()
  int row;
  @DeclareProperty()
  int col;

  // constructor

  Cell({required this.row, required this.col});
}

enum Direction {
  right,
  left,
  up,
  down,
}

@Dataclass()
@JsonSerializable(discriminatorField: "type", includeNull: false)
/*abstract*/ class WidgetData {
  // instance data

  final String type;
  @DeclareProperty(group: "general", label: "editor:groups.general", hide: true)
  @Json(required: false)
  final List<WidgetData> children;
  @Json(ignore: true)
  WidgetData? parent;
  @DeclareProperty(group: "general", label: "editor:groups.general", hide: true)
  Cell? cell;

  @Json(ignore: true)
  final id = Uuid().v4();
  @Json(ignore: true)
  AbstractEditorWidgetState? widget;

  // constructor

  WidgetData({required this.type, List<WidgetData>? children, this.cell}) : children = children ?? <WidgetData>[];

  // internal

  bool isParentOf(WidgetData w1, WidgetData w2) {
    WidgetData? w = w2.parent;
    while ( w != null) {
      if (w == w1)
        return true;
      w = w.parent;
    }

    return false;
  }

  int index() {
    return parent!.children.indexOf(this);
  }

  // public

  void update() {
    widget?.setState((){});
  }


  bool acceptsChild(WidgetData widget) {
    return !isParentOf(widget, this);
  }

  bool canMove(Direction direction) {
    return parent?.canMoveChild(this, direction) ?? false;
  }

  bool canMoveChild(WidgetData child, Direction direction) {
    return false;
  }
}
