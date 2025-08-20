import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix/i18n/i18n.dart';

import '../validation/validation.dart';
import 'valued_widget.dart';
import 'form_mapper.dart';

typedef DisplayValue<S,T> = T Function(S);
typedef ParseValue<S,T> = S Function(T text);

typedef Validator = String? Function(String value);

///  A [ValuedWidgetAdapter] for a [CupertinoTextFormFieldRow]
@WidgetAdapter()
class TextFieldAdapter extends AbstractTextWidgetAdapter<CupertinoTextFormFieldRow> {
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

    var displayValue, parseValue, validate, textInputType, inputFormatters;

    (displayValue, parseValue, validate, textInputType, inputFormatters) = customize(typeProperty);

    bool blurred = false;
    SmartFormState? form;

    void Function() getFocusListener(FocusNode focusNode) {
      return () {
        if ( !focusNode.hasFocus) {
          blurred = true;
          print("$path is blurred" );
        }
      };
    }

    if ( widgetProperty != null) {
      controller = widgetProperty.args["controller"];
      focusNode = widgetProperty.args["focusNode"];
    }
    else {
      controller = TextEditingController();
      focusNode = FocusNode();

      focusNode.addListener(getFocusListener(focusNode));

      controller.addListener(() {
        mapper.notifyChange(path: path, value: parseValue(controller!.text));

        if (form != null) {
          form!.validate();
        }
      });
    } // else

    String? Function(String? value) getValidator() {
      return (String? value) {
        final hasSubmitted = form?.submitted ?? false;
        final error = validate(value);

        // show only if for is submitted or the user has touched the field

        final showError = hasSubmitted || (typeProperty.isDirty() && blurred);

        return showError ? error : null;
      };
    }

    final key = GlobalKey();

    CupertinoTextFormFieldRow result = CupertinoTextFormFieldRow(
      key: key,
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      style: style,
      padding: padding,
      validator: getValidator(),
      keyboardType: textInputType,
      inputFormatters: inputFormatters
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      form = SmartForm.of(key.currentContext ?? context);
    });

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

abstract class AbstractTextWidgetAdapter<T> extends AbstractValuedWidgetAdapter<T> {
  (DisplayValue<dynamic,dynamic> displayValue, ParseValue<dynamic, dynamic> parseValue, FormFieldValidator<String> validate, TextInputType textInputTpye, List<TextInputFormatter> textInputFormatters) customize(TypeProperty typeProperty) {

    DisplayValue<dynamic,dynamic> displayValue = (dynamic value) => value.toString();
    ParseValue<dynamic, dynamic> parseValue = identity;
    TextInputType textInputType = TextInputType.text;
    List<TextInputFormatter> inputFormatters = [];

    if ( typeProperty.getType() == int) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: false);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*'))); // TODO
    }
    else if  ( typeProperty.getType() == double) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: true);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')));
    }

    String? validate(dynamic value) {
      try {
        typeProperty.validate(parseValue(value));

        return null;
      }
      on ValidationException catch(e) {
        return TranslationManager.translate(e.violations.first);
      }
      catch(e) {
        return e.toString();
      }
    }

    return (displayValue, parseValue, validate, textInputType, inputFormatters);
  }
}

///  A [ValuedWidgetAdapter] for a [TextFormField]
@WidgetAdapter()
class TextFormFieldAdapter extends AbstractTextWidgetAdapter<TextFormField> {
  // override

  @override
  void dispose(WidgetProperty property) {
    property.getArg<TextEditingController>("controller").dispose();
    property.getArg<FocusNode>("focusNode").dispose();
  }

  @override
  TextFormField build({required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}}) {
    var typeProperty = mapper.computeProperty(mapper.type, path);
    WidgetProperty? widgetProperty = mapper.findOperation(path)?.target as WidgetProperty?;

    DisplayValue<dynamic,dynamic> displayValue;
    ParseValue<dynamic, dynamic> parseValue;
    FormFieldValidator<String> validate;
    TextInputType textInputType;
    List<TextInputFormatter> inputFormatters;

    (displayValue, parseValue, validate, textInputType, inputFormatters) = customize(typeProperty);

    TextEditingController? controller;
    FocusNode? focusNode;

    if ( widgetProperty != null) {
      controller = widgetProperty.args["controller"];
      focusNode = widgetProperty.args["focusNode"];
    }
    else {
      controller = TextEditingController();
      focusNode = FocusNode();

      controller.addListener(() {
        mapper.notifyChange(path: path, value: parseValue(controller!.text)); // TODO: if the parse fails?
      });
    } // else

    // form hat: autovalidateMode: AutovalidateMode.onUserInteraction,

    TextFormField result = TextFormField(
      key: Key(path),
      controller: controller,
      focusNode: focusNode,
      style: args['style'] as TextStyle?,
      validator: validate,
      keyboardType: textInputType,
      inputFormatters: inputFormatters
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