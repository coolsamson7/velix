import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'valued_widget.dart';
import 'form_mapper.dart';

//import 'package:easy_localization/easy_localization.dart';

typedef DisplayValue<S,T> = T Function(S);
typedef ParseValue<S,T> = S Function(T text);

@WidgetAdapter()
class TextFieldAdapter extends AbstractValuedWidgetAdapter<CupertinoTextFormFieldRow> {
  // constructor

  TextFieldAdapter() : super(type: CupertinoTextFormFieldRow);

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
        typeProperty.field.type.validate(parseValue(value));

        return null;
      }
      catch(e) {
        return e.toString(); // TODO
      }
    }

    if ( typeProperty.field.type.type == int) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: false);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d*')));
    }
    else if  ( typeProperty.field.type.type == double) {
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
        var error = validate(controller!.text);

        final newValue = parseValue(controller.text);

        mapper.notifyChange(path: path, value: newValue);

        if (error != errorText) {
          print("error changed from $errorText to $error");
          errorText = error;
          //(context as Element).markNeedsBuild();

          //final formState = Form.of(context);

          //formState.validate();
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