import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'valued_widget.dart';
import 'form_mapper.dart';

///  A [ValuedWidgetAdapter] for a [Slider]
@WidgetAdapter()
class CheckboxAdapter extends AbstractValuedWidgetAdapter<Checkbox> {
  // constructor

  CheckboxAdapter() : super('checkbox', '');

  // override

  @override
  Checkbox build({required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}}) {
    var typeProperty = mapper.computeProperty(mapper.type, path);

    var initialValue = typeProperty.get(mapper.instance, ValuedWidgetContext(mapper: mapper));

    Checkbox widget = Checkbox.adaptive(
      value: initialValue,
      onChanged: (newValue) {
        (context as Element).markNeedsBuild();

        mapper.notifyChange(path: path, value: newValue);
      },
    );

    mapper.map(typeProperty: typeProperty, path: path, widget: widget, adapter: this);

    return widget;
  }

  @override
  dynamic getValue(Checkbox widget) {
    return widget.value;
  }

  @override
  void setValue(Checkbox widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}

extension CheckboxSlider on FormMapper {
  Widget checkbox({required String path,  required BuildContext context, required int min,  required int max}) {
    Map<String, dynamic> args = {
      "min": min,
      "max": max,
    };

    return bind("checkbox", path: path, context: context, args: args);
  }
}