import 'package:flutter/material.dart';
import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

///  A [ValuedWidgetAdapter] for a label
@WidgetAdapter(platforms: [TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS])
@Injectable()
class LabelAdapter extends AbstractValuedWidgetAdapter<Text> {
  // constructor

  LabelAdapter() : super('label', [TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS]);

  // override

  @override
  Text build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    var initialValue = mapper.getValue(property);

    var widget = Text(initialValue, key: ValueKey("$name:${property.path}"));

    //mapper.map(property: property, widget: widget, adapter: this);

    return widget;
  }

  @override
  dynamic getValue(Text widget) {
    return "label"; // TODO?
  }

  @override
  void setValue(Text widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}