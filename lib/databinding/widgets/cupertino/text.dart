import 'package:flutter/cupertino.dart';

import '../../../util/collections.dart';
import '../../form_mapper.dart';
import '../text.dart';
import '../../valued_widget.dart';

///  A [ValuedWidgetAdapter] for a [CupertinoTextFormFieldRow]
@WidgetAdapter()
class TextFieldAdapter extends AbstractTextWidgetAdapter<CupertinoTextFormFieldRow> {
  // constructor

  TextFieldAdapter() : super('text', 'iOS');

  // override

  @override
  void dispose(WidgetProperty property) {
    property.arg<TextEditingController>("controller").dispose();
    property.arg<FocusNode>("focusNode").dispose();
  }

  @override
  Widget build({required BuildContext context, required FormMapper mapper, required String path, required Keywords args}) {
    TextEditingController? controller;
    FocusNode? focusNode;

    var typeProperty = mapper.computeProperty(mapper.type, path);
    WidgetProperty? widgetProperty = mapper.findOperation(path)?.target as WidgetProperty?;

    var displayValue, parseValue, validate, textInputType, inputFormatters;

    (displayValue, parseValue, validate, textInputType, inputFormatters) = customize(typeProperty);

    bool blurred = false;
    SmartFormState? form;

    //final key = GlobalKey<FormFieldState>();

    void Function() getFocusListener(FocusNode focusNode) {
      return () {
        if ( !focusNode.hasFocus && typeProperty.isDirty()) {
          blurred = true;
          print("$path trigger validation");
          form!.triggerValidation();
          //key.currentState?.validate();
        }
      };
    }

    if ( widgetProperty != null) {
      controller = widgetProperty.arg("controller");
      focusNode = widgetProperty.arg("focusNode");
    }
    else {
      controller = TextEditingController();
      focusNode = FocusNode();

      focusNode.addListener(getFocusListener(focusNode));

      controller.addListener(() {
        try {
          var value = parseValue(controller!.text);
          mapper.notifyChange(path: path, value: value);

          if (form != null) {
            form!.triggerValidation();
            //key.currentState?.validate();
          }
        }
        catch(e) {
          // noop? the validation should take care
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

    CupertinoTextFormFieldRow result = CupertinoTextFormFieldRow(
          key: ValueKey(path), // key
          controller: controller,
          focusNode: focusNode,
          prefix: args.get<String>('prefix') != null ? Text(args.get<String>('prefix')!) : null,
          placeholder:  args.get<String>('placeholder'),
          style: args.get<TextStyle>('style'),
          padding: args.get<EdgeInsetsGeometry>('padding'),
          validator: getValidator(),
          keyboardType: textInputType,
          inputFormatters: inputFormatters
      );

    //key.currentState?.validate();

    mapper.map(typeProperty: typeProperty, path: path, widget: result, adapter: this, displayValue: displayValue, parseValue: parseValue);

    if ( widgetProperty == null) {
      widgetProperty = mapper.findOperation(path)?.target as WidgetProperty;

      widgetProperty.args["controller"] = controller;
      widgetProperty.args["focusNode"] = focusNode;
    }

    return Builder(
        builder: (ctx) {
          form = SmartForm.of(ctx);

          return result;
        });
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

      // clamp selection

      final maxOffset = newText.length;
      final start = previousSelection.start.clamp(0, maxOffset);
      final end = previousSelection.end.clamp(0, maxOffset);

      widget.controller!.selection = TextSelection(baseOffset: start, extentOffset: end);
    }
  }
}