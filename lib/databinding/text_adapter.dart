import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix/i18n/i18n.dart';

import '../validation/validation.dart';
import 'valued_widget.dart';
import 'form_mapper.dart';

typedef DisplayValue<S,T> = T Function(S);
typedef ParseValue<S,T> = S Function(T text);

///  A [ValuedWidgetAdapter] for a [CupertinoTextFormFieldRow]
@WidgetAdapter()
class TextFieldAdapter extends AbstractValuedWidgetAdapter<CupertinoTextFormFieldRow> {
  // constructor

  TextFieldAdapter();

  // override

  @override
  void dispose(WidgetProperty property) {
    property.getArg<TextEditingController>("controller").dispose();
    property.getArg<FocusNode>("focusNode").dispose();
  }

  @override
  CupertinoTextFormFieldRow build({required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}}) {
    TextEditingController? controller;
    FocusNode? focusNode;

    final placeholder = args['placeholder'] as String?;
    final style = args['style'] as TextStyle?;
    final padding = args['padding'] as EdgeInsetsGeometry?;

    var typeProperty = mapper.computeProperty(mapper.type, path);
    WidgetProperty? widgetProperty = mapper.findOperation(path)?.target as WidgetProperty?;

    DisplayValue<dynamic,dynamic> displayValue  = (dynamic value) => value.toString();
    ParseValue<dynamic,dynamic> parseValue = identity;

    TextInputType? textInputType;

    List<TextInputFormatter> inputFormatters = [];

    String? validate(dynamic value) {
      try {
        typeProperty.field!.type.validate(parseValue(value));

        return null;
      }
      on ValidationException catch(e) {
        return TranslationManager.translate(e.violations.first);
      }
      catch(e) {
        return e.toString();
      }
    }

    if ( typeProperty.field!.type.type == int) { // TODO AAAAAA
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: false);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*')));
    }
    else if  ( typeProperty.field!.type.type == double) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: true);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')));
    }

    String? errorText;

    if ( widgetProperty != null) {
      controller = widgetProperty.args["controller"];
      focusNode = widgetProperty.args["focusNode"];
    }
    else {
      controller = TextEditingController();

      controller.addListener(() {
        var error = validate(controller!.text); // does the coercion already!

        final newValue = parseValue(controller.text);

        mapper.notifyChange(path: path, value: newValue);

        if (error != errorText) {
          errorText = error;
        }
      });

      focusNode = FocusNode();
    } // else

    CupertinoTextFormFieldRow result = CupertinoTextFormFieldRow(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      style: style,
      padding: padding,
      validator: validate,
      keyboardType: textInputType,
      inputFormatters: inputFormatters,
      //errorText: errorText

    );

    mapper.map(typeProperty: typeProperty, path: path, widget: result, adapter: this, displayValue: displayValue, parseValue: parseValue);

    if ( widgetProperty == null) {
      widgetProperty = mapper.findOperation(path)?.target as WidgetProperty;

      widgetProperty.args["controller"] = controller;
      widgetProperty.args["focusNode"] = focusNode;
    }

    return result;
  }

  @override
  dynamic getValue(CupertinoTextFormFieldRow widget) {
    return widget.controller?.text;
  }

  @override
  void setValue(CupertinoTextFormFieldRow widget, dynamic value, ValuedWidgetContext context) {
    var newText =  value as String;

    if (newText != widget.controller?.text) {
      final previousSelection = widget.controller!.selection;

      // set text

      widget.controller?.text = newText;

      // restore cursor

      widget.controller!.selection = previousSelection;
    }
  }
}

///  A [ValuedWidgetAdapter] for a [TextFormField]
@WidgetAdapter()
class TextFormFieldAdapter extends AbstractValuedWidgetAdapter<TextFormField> {
  // override

  @override
  void dispose(WidgetProperty property) {
    property.getArg<TextEditingController>("controller").dispose();
    property.getArg<FocusNode>("focusNode").dispose();
  }

  @override
  TextFormField build({required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}}) {
    TextEditingController? controller;
    FocusNode? focusNode;

    final placeholder = args['placeholder'] as String?;
    final style = args['style'] as TextStyle?;
    final padding = args['padding'] as EdgeInsetsGeometry?;

    var typeProperty = mapper.computeProperty(mapper.type, path);
    WidgetProperty? widgetProperty = mapper.findOperation(path)?.target as WidgetProperty?;

    DisplayValue<dynamic,dynamic> displayValue  = (dynamic value) => value.toString();
    ParseValue<dynamic,dynamic> parseValue = identity;

    TextInputType? textInputType;

    List<TextInputFormatter> inputFormatters = [];

    String? validate(dynamic value) {
      try {
        typeProperty.field!.type.validate(value);

        return null;
      }
      on ValidationException catch(e) {
        return TranslationManager.translate(e.violations.first);
      }
      catch(e) {
        return e.toString();
      }
    }

    if ( typeProperty.field!.type.type == int) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: false);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*')));
    }
    else if  ( typeProperty.field!.type.type == double) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: true);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')));
    }

    String? errorText;

    if ( widgetProperty != null) {
      controller = widgetProperty.args["controller"];
      focusNode = widgetProperty.args["focusNode"];
    }
    else {
      controller = TextEditingController();

      controller.addListener(() {
        final newValue = parseValue(controller!.text);

        var error = validate(newValue);

        mapper.notifyChange(path: path, value: newValue);

        if (error != errorText) {
          errorText = error;
        }
      });

      focusNode = FocusNode();
    } // else

    TextFormField result = TextFormField(
      key: Key(path),
      controller: controller,
      focusNode: focusNode,
      style: style,
      validator: validate,
      keyboardType: textInputType,
      inputFormatters: inputFormatters,
      //errorText: errorText
    );

    mapper.map(typeProperty: typeProperty, path: path, widget: result, adapter: this, displayValue: displayValue, parseValue: parseValue);

    if ( widgetProperty == null) {
      widgetProperty = mapper.findOperation(path)?.target as WidgetProperty;

      widgetProperty.args["controller"] = controller;
      widgetProperty.args["focusNode"] = focusNode;
    }

    return result;
  }

  @override
  dynamic getValue(TextFormField widget) {
    return widget.controller?.text;
  }

  @override
  void setValue(TextFormField widget, dynamic value, ValuedWidgetContext context) {
    var newText =  value as String;

    if (newText != widget.controller?.text) {
      final previousSelection = widget.controller!.selection;

      // set text

      widget.controller?.text = newText;

      // restore cursor

      widget.controller!.selection = previousSelection;
    }
  }
}