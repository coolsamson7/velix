import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

///  A [ValuedWidgetAdapter] for a [Slider]
@WidgetAdapter(platforms: [TargetPlatform.iOS, TargetPlatform.macOS])
@Injectable()
class CupertinoSliderAdapter extends AbstractValuedWidgetAdapter<CupertinoSlider> {
  // constructor

  CupertinoSliderAdapter() : super('slider', [TargetPlatform.iOS, TargetPlatform.macOS]);

  // override

  @override
  Widget build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    var initialValue = mapper.getValue(property);

    CupertinoSlider widget = CupertinoSlider(
      key: ValueKey("$name:${property.path}"),
      value:  double.parse(initialValue.toString()),
      min: double.parse(args["min"].toString()),
      max: double.parse(args["max"].toString()),
      divisions: 10,
      onChanged: (newValue) {
        (context as Element).markNeedsBuild();

        mapper.notifyChange(property: property, value: newValue.round());
      },
    );

    mapper.map(property: property, widget: widget, adapter: this);

    return widget;
  }

  @override
  dynamic getValue(CupertinoSlider widget) {
    return int.parse(widget.value.toString());
  }

  @override
  void setValue(CupertinoSlider widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}