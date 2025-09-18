import 'package:velix/reflectable/reflectable.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "container", group: "Container")
class ContainerWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  List<WidgetData> children;

  // constructor

  ContainerWidgetData({required this.children, super.type = "container"});
}
