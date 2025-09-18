
import 'package:velix/reflectable/reflectable.dart';

@Dataclass()
abstract class WidgetData {
  String type;

  WidgetData({required this.type});
}
