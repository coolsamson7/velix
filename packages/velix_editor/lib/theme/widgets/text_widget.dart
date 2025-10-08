import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:velix/i18n/translator.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart' show ValidationException;
import 'package:velix_di/di/di.dart';
import 'package:velix_ui/databinding/form_mapper.dart';
import 'package:velix_ui/databinding/valued_widget.dart';
import 'package:velix_ui/databinding/widgets/material/text.dart';

import '../../metadata/widgets/text.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class TextWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // constructor

  TextWidgetBuilder() : super(name: "text");

  // internal

  (DisplayValue<dynamic,dynamic> displayValue, ParseValue<dynamic, dynamic> parseValue, FormFieldValidator<String> validate, TextInputType textInputTpye, List<TextInputFormatter> textInputFormatters) customize(TypeProperty typeProperty) {

    DisplayValue<dynamic,dynamic> displayValue = (dynamic value) => value.toString();
    ParseValue<dynamic, dynamic> parseValue = identity;
    TextInputType textInputType = TextInputType.text;
    List<TextInputFormatter> inputFormatters = [];

    if ( typeProperty.getType() == int) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: false);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')));
    }
    else if  ( typeProperty.getType() == double) {
      parseValue = (dynamic value) => int.parse(value);
      textInputType = TextInputType.numberWithOptions(decimal: true);
      inputFormatters.add(FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')));
    }

    String? validate(dynamic value) {
      try {
        late dynamic propValue;

        try {
          propValue = parseValue(value);
          typeProperty.validate(propValue);
        }
        catch(e) {
          if ( e is ValidationException)
            rethrow;
          else
            typeProperty.validate(null); // should a t least get a good text
        }

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

  // override

  @override
  Widget create(TextWidgetData data, Environment environment, BuildContext context) {
    var widgetContext = Provider.of<WidgetContext>(context);

    var mapper = widgetContext.formMapper;
    var instance = widgetContext.page;

    TextEditingController controller =  TextEditingController();
    FocusNode? focusNode = FocusNode();

    var adapter = environment.get<MaterialTextFormFieldAdapter>();

    var typeProperty = data.databinding != null && data.databinding!.isNotEmpty ? mapper.computeProperty(TypeDescriptor.forType(instance.runtimeType), data.databinding!) : null;

    TextFormField result;

    if (typeProperty != null) {
      var (displayValue, parseValue, validate, textInputType, inputFormatters) = customize(typeProperty!);

      controller.addListener(() {
        var value = parseValue(controller.text);

        mapper.notifyChange(property: typeProperty, value: value);

        //if (form != null) {
        //  form!.triggerValidation();
      });

      //TODO getValidator -> FormMapping!
      // TODO Form!

      result = TextFormField(
          key: ValueKey(data.databinding),
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: data.label),
          validator: validate,
          keyboardType: textInputType,
          inputFormatters: inputFormatters
      );

      mapper.map(property: typeProperty, widget: result, adapter: adapter, displayValue: displayValue, parseValue: parseValue);
    }
    else result = TextFormField(
        key: ValueKey(data.databinding),
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(labelText: data.label)
    );


    return result;
  }
}

@Injectable()
class TextEditWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // constructor

  TextEditWidgetBuilder() : super(name: "text", edit: true);

  // override


  @override
  Widget create(TextWidgetData data, Environment environment, BuildContext context) {
    // In edit mode, make the text field non-interactive
    return IgnorePointer(
      ignoring: true,
      child: TextField(
        decoration: InputDecoration(labelText: data.label),
        // Optional: You might also want to disable the field visually
        enabled: false, // This makes it look disabled but IgnorePointer is what actually blocks interaction
      ),
    );
  }
}