
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/annotations.dart';
import 'package:velix_mapper/mapper/json.dart';

@Dataclass()
@JsonSerializable(discriminatorField: "type")
/*abstract*/ class WidgetData {
  // instance data

  final String type;
  @DeclareProperty(group: "general", hide: true)
  @Json(required: false)
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
