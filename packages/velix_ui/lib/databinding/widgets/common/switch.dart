import 'package:flutter/material.dart';
import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

///  A [ValuedWidgetAdapter] for a [Switch]
@WidgetAdapter(platforms: [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS])
@Injectable()
class SwitchAdapter extends AbstractValuedWidgetAdapter<Switch> {
  // constructor

  SwitchAdapter() : super('switch', [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS]);

  // override

  @override
  Switch build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    Switch widget = Switch.adaptive(
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
  dynamic getValue(Switch widget) {
    return widget.value;
  }

  @override
  void setValue(Switch widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}