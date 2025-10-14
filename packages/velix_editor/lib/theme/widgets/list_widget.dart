import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:provider/provider.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_editor/metadata/type_registry.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../../dynamic_widget.dart';
import '../../editor/editor.dart';
import '../../metadata/widgets/label.dart';
import '../../metadata/widgets/list.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class ListWidgetBuilder extends WidgetBuilder<ListWidgetData> {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  ListWidgetBuilder({required this.typeRegistry}) : super(name: "list");

  // override

  @override
  Widget create(ListWidgetData data, Environment environment, BuildContext context) {
    var widgetContext =  WidgetContextScope.of(context);

    //var (label, typeProperty) = resolveValue(widgetContext, data.label);

    var users = [
      User(
          name: 'Andreas',
          address: Address(
              city: "Köln",
              street: "Street"
          ),
          age: 60, single: true
      ),
      User(
          name: 'Sandra',
          address: Address(
              city: "Köln",
              street: "Street"
          ),
          age: 60, single: true
      ),
    ];

    Widget createChild(User user) {
      // TODO: formMapper, container, bindings?

      var newContext = WidgetContext(
          instance: user
      );

      return WidgetContextScope(
          contextValue: newContext, 
          child: DynamicWidget(
            model: data.template,
            meta: typeRegistry[data.template.type]
      ));
    }

    var result = ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: users.map((user) => createChild(user)).toList(),
        //style: data.font?.textStyle(color: data.color, backgroundColor: data.backgroundColor)
    );

    //if (data.label.type == ValueType.binding) {
    //    widgetContext.addBinding(typeProperty!, data);
    //}

    return result;
  }
}

@Injectable()
class EditListWidgetBuilder extends WidgetBuilder<ListWidgetData> {
  // constructor

  EditListWidgetBuilder() : super(name: "list", edit: true);

  // override

  @override
  Widget create(ListWidgetData data, Environment environment, BuildContext context) {
    var label = "data.label.value";
    /*switch (data.label.type) {
      case ValueType.i18n:
        label = label.tr();
        break;
      case ValueType.binding:
        //widgetContext.addBinding(label, data);
        break;
      case ValueType.value:
        break;
    }*/


    return SizedBox(
      height: 20,
        child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [

        Text("List Children"),
      ]
          //style: data.font?.textStyle()
      ));
  }
}