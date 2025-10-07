
import 'package:intl/intl.dart';

import 'package:flutter/widgets.dart';

import 'package:velix/util/collections.dart';

import "form_mapper.dart";

// text

extension BindText on FormMapper {
  Widget text({required String path,  required BuildContext context,  String? prefix, String? placeholder, TextStyle? style, EdgeInsetsGeometry? padding}) {
    return bind("text", path: path, context: context, args: Keywords({
      "placeholder": placeholder,
      "style": style,
      "prefix": prefix,
      "padding": padding,
    }));
  }
}

// slider

extension BindSlider on FormMapper {
  Widget slider({required String path,  required BuildContext context, required int min,  required int max}) {
    return bind("slider", path: path, context: context, args: Keywords({
      "min": min,
      "max": max,
    }));
  }
}

// switch

extension BindSwitch on FormMapper {
  Widget Switch({required String path,  required BuildContext context}) {
    return bind("switch", path: path, context: context, args: Keywords({}));
  }
}

// checkbox

extension BindCheckbox on FormMapper {
  Widget checkbox({required String path,  required BuildContext context}) {
    return bind("checkbox", path: path, context: context, args: Keywords({}));
  }
}

// datepicker

extension DatePickerFormFieldExtension on FormMapper {
  Widget date({
    required String path,
    required BuildContext context,
    DateTime? firstDate,
    DateTime? lastDate,
    String? label,
    DateFormat? dateFormat,
  }) {
    return bind('date', path: path, context: context, args: Keywords({
      'firstDate': firstDate,
      'lastDate': lastDate,
      'dateFormat': dateFormat
    }));
  }
}