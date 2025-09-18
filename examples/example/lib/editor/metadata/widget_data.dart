
import 'package:velix/reflectable/reflectable.dart';

import 'annotations.dart';

@Dataclass()
abstract class WidgetData {
  // instance data

  String type;
  @DeclareProperty(group: "general")
  List<WidgetData> children;
  WidgetData? parent;

  // constructor

  WidgetData({required this.type, this.children = const []});
}
