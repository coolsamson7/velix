import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:provider/provider.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../../dynamic_widget.dart';
import '../../editor/editor.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widgets/dropdown.dart';
import '../../metadata/widgets/label.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class DropDownWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  DropDownWidgetBuilder({required this.typeRegistry}) : super(name: "dropdown");

  // override

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    var widgetContext =  WidgetContextScope.of(context);

    String? selectedValue = "f";


    List<User> users = [
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


    //var (label, typeProperty) = resolveValue(widgetContext, data.label);

    DropdownMenuItem<User> createChild(User user) {
      // TODO: formMapper, container, bindings?

      var newContext = WidgetContext(
          instance: user
      );

      return DropdownMenuItem<User>(
              value: user,
              child:  WidgetContextScope(
                  contextValue: newContext,
                  child: DynamicWidget(
                model: data.template,
                meta: typeRegistry[data.template.type]
          )
            )
      );
    }

    var result = DropdownButton<User>(
        value: null,
        hint: const Text('Select a user'),
        items: users.map((user) => createChild(user)).toList(),
        onChanged: (User? value) {  }
    );

   /* if (data.label.type == ValueType.binding) {
        widgetContext.addBinding(typeProperty!, data);
    }*/

    return SizedBox(
        width: double.infinity,
        child: result
    );
  }
}

@Injectable()
class DropDownEditWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  // constructor

  DropDownEditWidgetBuilder() : super(name: "dropdown", edit: true);

  // override

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
          width: double.infinity,
          child: DropdownButton<String>(
          value: "item",
          hint: const Text('Select an item'),
          items: <String>["item"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(), onChanged: (String? value) {  },
      )
      )
    );
  }
}