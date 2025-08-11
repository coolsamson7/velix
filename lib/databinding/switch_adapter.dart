import 'package:flutter/cupertino.dart';

import 'package:flutter_application/databinding/valued_widget.dart';
import 'package:flutter_application/databinding/form_mapper.dart';

@WidgetAdapter()
class CupertinoSwitchAdapter extends AbstractValuedWidgetAdapter<CupertinoSwitch> {
  // constructor

  CupertinoSwitchAdapter() : super(type: CupertinoSwitch);

  // override

  @override
  CupertinoSwitch build({required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}}) {
    var typeProperty = mapper.computeProperty(mapper.type, path);

    var initialValue = typeProperty.get(mapper.instance, ValuedWidgetContext(mapper: mapper));

    CupertinoSwitch widget = CupertinoSwitch(
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
  dynamic getValue(CupertinoSwitch widget) {
    return widget.value;
  }

  @override
  void setValue(CupertinoSwitch widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}