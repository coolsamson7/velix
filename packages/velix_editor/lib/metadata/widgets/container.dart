import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "container", group: "Container")
@JsonSerializable(discriminator: "container")
class ContainerWidgetData extends WidgetData {
  // instance data

  // constructor

  ContainerWidgetData({required super.children, super.type = "container"});
}
