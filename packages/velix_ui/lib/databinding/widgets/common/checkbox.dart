import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

///  A [ValuedWidgetAdapter] for a [Slider]
@WidgetAdapter(platforms: [TargetPlatform.android])
@Injectable()
class CheckboxAdapter extends AbstractValuedWidgetAdapter<Checkbox> {
  // constructor

  CheckboxAdapter() : super('checkbox', [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS]);

  // override

  @override
  Checkbox build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    Checkbox widget = Checkbox.adaptive(
      key: ValueKey("$name:${property.path}"),
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