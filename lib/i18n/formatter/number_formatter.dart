
import 'dart:ui';

import 'package:intl/intl.dart';

import '../i18n.dart';

class NumberFormatter extends Formatter {
  // override

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    NumberFormat format = NumberFormat.decimalPattern(locale(formatterArgs));

    if (formatterArgs["maximumFractionDigits"] != null)
      format.maximumFractionDigits = formatterArgs["maximumFractionDigits"];

    if (formatterArgs["minimumFractionDigits"] != null)
      format.minimumFractionDigits = formatterArgs["minimumFractionDigits"];

    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}

class CurrencyFormatter extends Formatter {
  // override

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    var format = NumberFormat.currency(
      locale: locale(formatterArgs),
        name: formatterArgs["name"],
        decimalDigits: formatterArgs["decimalDigits"]
    );

    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}
