import 'package:flutter/material.dart';

import '../../../util/collections.dart';
import '../../form_mapper.dart';
import '../../valued_widget.dart';

///  A [ValuedWidgetAdapter] for a [Switch]
@WidgetAdapter()
class SwitchAdapter extends AbstractValuedWidgetAdapter<Switch> {
  // constructor

  SwitchAdapter() : super('switch', 'material');

  // override

  @override
  Switch build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    Switch widget = Switch(
      value: mapper.getValue(property),
      onChanged: (bool newValue) {
        (context as Element).markNeedsBuild();

        mapper.notifyChange(property: property, value: newValue);
      },
    );

    mapper.map(property: property, widget: widget, adapter: this);

    return widget;
  }

  @override
  dynamic getValue(Switch widget) {
    return widget.value;
  }

  @override
  void setValue(Switch widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}

extension BindSwitch on FormMapper {
  Widget Switch({required String path,  required BuildContext context}) {
    return bind("switch", path: path, context: context, args: Keywords({}));
  }
}