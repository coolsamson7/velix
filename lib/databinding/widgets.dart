
import 'package:intl/intl.dart';


import 'package:flutter/widgets.dart';
import 'package:velix/databinding/widgets/cupertino/registry.dart';
import 'package:velix/databinding/widgets/material/registry.dart';

import '../util/collections.dart';
import 'form_mapper.dart';

void registerWidgets(TargetPlatform platform) {
  if ( platform == TargetPlatform.iOS || platform == TargetPlatform.macOS)
    registerCupertinoWidgets();
  else if ( platform == TargetPlatform.android)
    registerMaterialWidgets();
  else
    throw Exception("unsupported platform $platform");
}

// text

extension BindText on FormMapper {
  Widget text({required String path,  required BuildContext context,  String? placeholder, TextStyle? style, EdgeInsetsGeometry? padding}) {
    return bind("text", path: path, context: context, args: Keywords({
      "placeholder": placeholder,
      "style": style,
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

extension CheckboxSlider on FormMapper {
  Widget checkbox({required String path,  required BuildContext context, required int min,  required int max}) {
    return bind("checkbox", path: path, context: context, args: Keywords({
      "min": min,
      "max": max,
    }));
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