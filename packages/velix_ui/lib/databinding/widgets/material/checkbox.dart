import 'package:flutter/material.dart';

import 'package:velix/velix.dart';
import 'package:velix_i18n/velix_i18n.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

///  A [ValuedWidgetAdapter] for a [Slider]
@WidgetAdapter()
class CheckboxAdapter extends AbstractValuedWidgetAdapter<Checkbox> {
  // constructor

  CheckboxAdapter() : super('checkbox', 'material');

  // override

  @override
  Checkbox build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    Checkbox widget = Checkbox.adaptive(
      value: mapper.getValue(property),
      onChanged: (newValue) {
        (context as Element).markNeedsBuild();

        mapper.notifyChange(property: property, value: newValue);
      },
    );

    mapper.map(property: property, widget: widget, adapter: this);

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
    return bind("checkbox", path: path, context: context, args: Keywords({
      "min": min,
      "max": max,
    }));
  }
}