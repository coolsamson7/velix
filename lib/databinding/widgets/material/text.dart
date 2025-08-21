import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../util/collections.dart';
import '../../form_mapper.dart';
import '../text.dart';
import '../../valued_widget.dart';

///  A [ValuedWidgetAdapter] for a [TextFormField]
@WidgetAdapter()
class TextFormFieldAdapter extends AbstractTextWidgetAdapter<TextFormField> {
  // constructor

  TextFormFieldAdapter():super("text", "");

  // override

  @override
  void dispose(WidgetProperty property) {
    property.arg<TextEditingController>("controller").dispose();
    property.arg<FocusNode>("focusNode").dispose();
  }

  @override
  Widget build({required BuildContext context, required FormMapper mapper, required String path, required Keywords args}) {
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
        mapper.notifyChange(path: path, value: parseValue(controller!.text));
      });
    } // else

    TextFormField result = TextFormField(
      key: ValueKey(path),
      controller: controller,
      focusNode: focusNode,
      style: args.get<TextStyle>('style'),
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