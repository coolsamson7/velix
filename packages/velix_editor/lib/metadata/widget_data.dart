
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/annotations.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../edit_widget.dart';

@Dataclass()
class Cell {
  @DeclareProperty()
  int row;
  @DeclareProperty()
  int col;

  // constructor

  Cell({required this.row, required this.col});
}

@Dataclass()
@JsonSerializable(discriminatorField: "type", includeNull: false)
/*abstract*/ class WidgetData {
  // instance data

  final String type;
  @DeclareProperty(group: "general", label: "editor:groups.general", hide: true)
  @Json(required: false)
  List<WidgetData> children;
  @Json(ignore: true)
  WidgetData? parent;
  @DeclareProperty(group: "general", label: "editor:groups.general", hide: true)
  Cell? cell;

  @Json(ignore: true)
  EditWidgetState? widget;

  // constructor

  WidgetData({required this.type, this.children = const [], this.cell});

  // public

  bool acceptsChild(WidgetData widget) {
    return false;
  }
}
