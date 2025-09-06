import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:velix/velix.dart';

import '../form_mapper.dart';
import '../valued_widget.dart';


typedef Validator = String? Function(String value);

abstract class AbstractTextWidgetAdapter<T> extends AbstractValuedWidgetAdapter<T> {
  // constructor

  AbstractTextWidgetAdapter(super.name, super.theme);

  // protected

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
}
