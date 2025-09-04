import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix/velix.dart';
import 'package:velix_ui/velix_ui.dart';

import '../text.dart';

///  A [ValuedWidgetAdapter] for a [TextFormField]
@WidgetAdapter()
class TextFormFieldAdapter extends AbstractTextWidgetAdapter<TextFormField> {
  // constructor

  TextFormFieldAdapter():super("text", "material");

  // override

  @override
  void dispose(WidgetProperty property) {
    property.arg<TextEditingController>("controller").dispose();
    property.arg<FocusNode>("focusNode").dispose();
  }

  @override
  Widget build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    WidgetProperty? widgetProperty = mapper.findWidget(property.path);

    DisplayValue<dynamic,dynamic> displayValue;
    ParseValue<dynamic, dynamic> parseValue;
    FormFieldValidator<String> validate;
    TextInputType textInputType;
    List<TextInputFormatter> inputFormatters;

    (displayValue, parseValue, validate, textInputType, inputFormatters) = customize(property);

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
        mapper.notifyChange(property: property, value: parseValue(controller!.text));
      });
    } // else

    TextFormField result = TextFormField(
      key: ValueKey(property.path),
      controller: controller,
      focusNode: focusNode,
      style: args.get<TextStyle>('style'),
      validator: validate,
      keyboardType: textInputType,
      inputFormatters: inputFormatters
    );

    mapper.map(property: property, widget: result, adapter: this, displayValue: displayValue, parseValue: parseValue);

    if ( widgetProperty == null) {
      widgetProperty = mapper.findWidget(property.path)!;

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

      // clamp selection

      final maxOffset = newText.length;
      final start = previousSelection.start.clamp(0, maxOffset);
      final end = previousSelection.end.clamp(0, maxOffset);

      widget.controller!.selection = TextSelection(baseOffset: start, extentOffset: end);
    }
  }
}