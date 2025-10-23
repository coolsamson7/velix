import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';

@Dataclass()
@DeclareWidget(name: "list", group: "widgets", icon: "widget_listview")
@JsonSerializable(discriminator: "list", includeNull: false)
class ListWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "style")
  Insets? padding;

  // constructor

  ListWidgetData({super.type = "list", this.padding, super.cell, super.children});
}