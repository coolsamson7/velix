import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "container", i18n: "widgets:container", group: "container", icon: Icons.view_column)
@JsonSerializable(discriminator: "container")
class ContainerWidgetData extends WidgetData {
  // instance data

  // constructor

  ContainerWidgetData({super.type = "container", super.children = const []});

  // override

  @override
  bool acceptsChild(WidgetData widget) { // TODO parent -> child
    return widget.parent != this;
  }
}
