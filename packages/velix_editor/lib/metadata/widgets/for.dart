import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../../property_panel/editor/code_editor.dart';
import '../../validate/validate.dart';
import '../annotations.dart';
import '../widget_data.dart';


@Dataclass()
@DeclareWidget(name: "for", group: "logic", icon: "widget_for")
@JsonSerializable(discriminator: "for", includeNull: false)
class ForWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "data",  editor: CodeEditorBuilder, validator: ContextPropertyValidator)
  String context;

  // constructor

  ForWidgetData({this.context = "", super.type = "for", super.cell, super.children});

  // override

  @override
  bool acceptsChild(WidgetData widget) {
    return !isParentOf(widget, this);
  }
}
