
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import 'annotations.dart';

@Dataclass()
@JsonSerializable(discriminatorField: "type")
abstract class WidgetData {
  // instance data

  String type;
  @DeclareProperty(group: "general", hide: true)
  List<WidgetData> children;
  WidgetData? parent;

  // constructor

  WidgetData({required this.type, this.children = const []});

  // public

  bool acceptsChild(WidgetData widget) {
    return false;
  }
}
