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
  Widget build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    TextEditingController? controller;
    FocusNode? focusNode;

    WidgetProperty? widgetProperty = mapper.findWidget(property.path);

    var (displayValue, parseValue, validate, textInputType, inputFormatters) = customize(property);

    bool blurred = false;
    SmartFormState? form;

    //final key = GlobalKey<FormFieldState>();

    void Function() getFocusListener(FocusNode focusNode) {
      return () {
        if ( !focusNode.hasFocus && property.isDirty()) {
          blurred = true;
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
          mapper.notifyChange(property: property, value: value);

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

        final showError = hasSubmitted || (property.isDirty() && blurred);

        return showError ? error : null;
      };
    }

    CupertinoTextFormFieldRow result = CupertinoTextFormFieldRow(
          key: ValueKey(property.path), // key
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

    // new binding

    mapper.map(property: property, widget: result, adapter: this, displayValue: displayValue, parseValue: parseValue);

    if ( widgetProperty == null) {
      widgetProperty = mapper.findWidget(property.path)!;

      widgetProperty.setArg("controller", controller);
      widgetProperty.setArg("focusNode", focusNode);
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