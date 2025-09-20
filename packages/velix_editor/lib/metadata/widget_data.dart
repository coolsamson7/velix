
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

@Dataclass()
@JsonSerializable(discriminatorField: "type")
abstract class WidgetData {
  // instance data

  String type;
  List<WidgetData> children;
  @Json(ignore: true)
  WidgetData? parent;

  // constructor

  WidgetData({required this.type, this.children = const []});

  // public

  bool acceptsChild(WidgetData widget) {
    return false;
  }
}
