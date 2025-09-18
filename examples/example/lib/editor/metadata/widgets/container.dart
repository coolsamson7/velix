import 'package:velix/reflectable/reflectable.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "container", group: "Container")
class ContainerWidgetData extends WidgetData {
  // instance data

  // constructor

  ContainerWidgetData({required super.children, super.type = "container"});
}
