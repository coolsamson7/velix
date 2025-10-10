
import 'package:flutter/material.dart' hide Padding;
import 'package:velix/i18n/translator.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_ui/databinding/form_mapper.dart';
import 'package:velix_ui/databinding/valued_widget.dart';
import '../../metadata/properties/properties.dart' as Props;
import 'package:velix_di/di/di.dart';

import '../metadata/properties/properties.dart' hide Border;
import '../metadata/widget_data.dart';
import '../widget_container.dart';
import 'theme.dart';

extension InsetsHelper on Props.Insets {
  EdgeInsets edgeInsets() {
    return EdgeInsets.fromLTRB(left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
  }
}

extension FontHelper on Props.Font {
  TextStyle textStyle({Color? color, Color? backgroundColor}) {
      return TextStyle(
        color: color,
        backgroundColor: backgroundColor,
        fontFamily: family,
        fontSize: size.toDouble(),
        fontWeight: weight,
        fontStyle: style,
      );
  }
}

extension BorderHelper on Props.Border {
  Border border() {
    return  Border.all(
        color: color,
        width: width.toDouble(),
        style: BorderStyle.solid
    );
  }
}

@Injectable(factory: false, eager: false)
abstract class WidgetBuilder<T extends WidgetData> {
  // instance data

  String name;
  bool edit;

  // constructor

  WidgetBuilder({required this.name, this.edit = false});

  // lifecycle

  @Inject()
  void setThema(WidgetFactory theme) {
    theme.register(this, name, edit);
  }

  // protected

  // internal

  (String, TypeProperty?) resolveValue(WidgetContext widgetContext, Props.Value value) {
    var result = value.value;

    var mapper = widgetContext.formMapper;
    var instance = widgetContext.instance;

    TypeProperty? typeProperty;
    if (value.type == ValueType.i18n)
      result = Translator.tr(result);

    else if (value.type == ValueType.binding) {
      typeProperty = mapper.computeProperty(TypeDescriptor.forType(instance.runtimeType), result);
      result = typeProperty.get(instance, ValuedWidgetContext(mapper: mapper));
    }

    return (result, typeProperty);
  }

  // abstract

  Widget create(T data, Environment environment, BuildContext context);
}

