import 'package:flutter/material.dart';
import 'package:velix/i18n/translator.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_ui/databinding/form_mapper.dart';
import 'package:velix_ui/databinding/valued_widget.dart';

import '../metadata/properties/properties.dart';
import '../widget_container.dart';

abstract class AbstractWidgetState<T extends StatefulWidget> extends State<T> {
  // protected

  (String, TypeProperty?) resolveValue(WidgetContext widgetContext, Value value) {
    var result = value.value;

    var mapper = widgetContext.formMapper;
    var instance = widgetContext.instance;

    TypeProperty? typeProperty;
    if (value.type == ValueType.i18n)
      result = Translator.tr(result);

    else if (value.type == ValueType.binding) {
      typeProperty = mapper.computeProperty(widgetContext.typeDescriptor, result);
      result = typeProperty.get(instance, ValuedWidgetContext(mapper: mapper));
    }

    return (result, typeProperty);
  }
}