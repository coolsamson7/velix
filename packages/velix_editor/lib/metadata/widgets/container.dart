import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../properties/properties.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "container", group: "container", icon: "widget_container")
@JsonSerializable(discriminator: "container", includeNull: false)
class ContainerWidgetData extends WidgetData {
  // instance data

  Border? border;
  Insets? padding;
  Insets? margin;

  // constructor

  ContainerWidgetData({super.type = "container", this.border, this.margin, this.padding, super.children = const []});

  // override

  @override
  bool acceptsChild(WidgetData widget) { // TODO parent -> child
    return widget.parent != this;
  }
}
