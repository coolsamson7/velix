import 'package:flutter/material.dart';
import 'package:velix/i18n/translator.dart';
import 'package:velix_ui/databinding/form_mapper.dart';
import 'package:velix_ui/databinding/valued_widget.dart';

import '../actions/action_evaluator.dart';
import '../actions/eval.dart';
import '../metadata/properties/properties.dart';
import '../widget_container.dart';

abstract class AbstractEditorWidgetState<T extends StatefulWidget> extends AbstractWidgetState<T> {
  // protected

  T compile<T>(String expression) {
    var widgetContext = WidgetContextScope.of(context);

    final call = ActionCompiler.instance.compile(expression, context: widgetContext.typeDescriptor);
    final evalContext = EvalContext(instance: widgetContext.instance, variables: {});

    return (() => call.eval(widgetContext.instance, evalContext)) as T;
  }

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