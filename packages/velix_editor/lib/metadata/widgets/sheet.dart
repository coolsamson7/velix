import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';

/// data class for the main sheet as the root of everything
@Dataclass()
@DeclareWidget(name: "sheet", group: "container", icon: "widget_column")
@JsonSerializable(discriminator: "sheet", includeNull: false)
class SheetWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String name;

  // constructor

  SheetWidgetData({this.name = "", super.type = "sheet", super.cell, super.children});

  // override

  @override
  bool acceptsChild(WidgetData widget) {
    return children.isEmpty;
  }
}
