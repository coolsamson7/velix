import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

///  A [ValuedWidgetAdapter] for a [Switch]
@WidgetAdapter(platforms: [TargetPlatform.iOS, TargetPlatform.macOS])
@Injectable()
class CupertinoSwitchAdapter extends AbstractValuedWidgetAdapter<CupertinoSwitch> {
  // constructor

  CupertinoSwitchAdapter() : super('switch', [TargetPlatform.iOS, TargetPlatform.macOS]);

  // override

  @override
  CupertinoSwitch build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    CupertinoSwitch widget = CupertinoSwitch(
      key: ValueKey("$name:${property.path}"),
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
  dynamic getValue(CupertinoSwitch widget) {
    return widget.value;
  }

  @override
  void setValue(CupertinoSwitch widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}