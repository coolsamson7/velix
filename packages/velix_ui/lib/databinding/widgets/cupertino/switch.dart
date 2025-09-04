import 'package:flutter/cupertino.dart';

import 'package:velix/velix.dart';
import 'package:velix_ui/velix_ui.dart';

///  A [ValuedWidgetAdapter] for a [CupertinoSwitch]
@WidgetAdapter()
class SwitchAdapter extends AbstractValuedWidgetAdapter<CupertinoSwitch> {
  // constructor

  SwitchAdapter() : super('switch', 'iOS');

  // override

  @override
  CupertinoSwitch build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    CupertinoSwitch widget = CupertinoSwitch(
      value: mapper.getValue(property),
      onChanged: (bool newValue) {
        mapper.notifyChange(property: property, value: newValue);
      },
    );

    mapper.map(property: property, widget: widget, adapter: this);

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

extension BindSwitch on FormMapper {
  Widget Switch({required String path, required BuildContext context}) {
    return bind("switch", path: path, context: context, args: Keywords({}));
  }
}