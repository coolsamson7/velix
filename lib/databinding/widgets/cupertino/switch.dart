import 'package:flutter/cupertino.dart';

import '../../../util/collections.dart';
import '../../form_mapper.dart';
import '../../valued_widget.dart';

///  A [ValuedWidgetAdapter] for a [CupertinoSwitch]
@WidgetAdapter()
class SwitchAdapter extends AbstractValuedWidgetAdapter<CupertinoSwitch> {
  // constructor

  SwitchAdapter() : super('switch', 'iOS');

  // override

  @override
  CupertinoSwitch build({required BuildContext context, required FormMapper mapper, required String path, required Keywords args}) {
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

extension BindSwitch on FormMapper {
  Widget Switch({required String path,  required BuildContext context}) {
    return bind("switch", path: path, context: context, args: Keywords({}));
  }
}