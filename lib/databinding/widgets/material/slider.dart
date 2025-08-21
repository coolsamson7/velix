import 'package:flutter/material.dart';

import '../../../util/collections.dart';
import '../../form_mapper.dart';
import '../../valued_widget.dart';

///  A [ValuedWidgetAdapter] for a [Slider]
@WidgetAdapter()
class SliderAdapter extends AbstractValuedWidgetAdapter<Slider> {
  // constructor

  SliderAdapter() : super('slider', 'material');

  // override

  @override
  Slider build({required BuildContext context, required FormMapper mapper, required String path, required Keywords args}) {
    var typeProperty = mapper.computeProperty(mapper.type, path);

    var initialValue = typeProperty.get(mapper.instance, ValuedWidgetContext(mapper: mapper));

    Slider widget = Slider(
      value:  double.parse(initialValue.toString()),
      min: double.parse(args["min"].toString()),
      max: double.parse(args["max"].toString()),
      divisions: 10,
      onChanged: (newValue) {
        (context as Element).markNeedsBuild();

        mapper.notifyChange(path: path, value: newValue.round());
      },
    );

    mapper.map(typeProperty: typeProperty, path: path, widget: widget, adapter: this);

    return widget;
  }

  @override
  dynamic getValue(Slider widget) {
    return int.parse(widget.value.toString());
  }

  @override
  void setValue(Slider widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}

extension BindSlider on FormMapper {
  Widget slider({required String path,  required BuildContext context, required int min,  required int max}) {
    return bind("slider", path: path, context: context, args: Keywords({
      "min": min,
      "max": max,
    }));
  }
}