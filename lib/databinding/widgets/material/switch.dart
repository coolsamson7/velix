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
  Switch build({required BuildContext context, required FormMapper mapper, required String path, required Keywords args}) {
    var typeProperty = mapper.computeProperty(mapper.type, path);

    var initialValue = typeProperty.get(mapper.instance, ValuedWidgetContext(mapper: mapper));

    Switch widget = Switch(
      value: initialValue,
      onChanged: (bool newValue) {
        (context as Element).markNeedsBuild();

        mapper.notifyChange(path: path, value: newValue);
      },
    );

    mapper.map(typeProperty: typeProperty, path: path, widget: widget, adapter: this);

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