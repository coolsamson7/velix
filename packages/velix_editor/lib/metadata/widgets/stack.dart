import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "stack", group: "container", icon: "widget_stack")
@JsonSerializable(discriminator: "stack", includeNull: false)
class StackWidgetData extends WidgetData {
  // instance data

  // constructor

  StackWidgetData({super.type = "stack", super.cell, super.children});
}
