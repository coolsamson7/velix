
import 'package:intl/intl.dart';

import '../i18n.dart';

class NumberFormatter extends Formatter {
  // instance data

  late NumberFormat format;

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    format = NumberFormat.decimalPattern();
    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}

class CurrencyFormatter extends Formatter {
  // instance data

  late NumberFormat format;

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    format = NumberFormat.currency(symbol: formatterArgs["symbol"], decimalDigits: formatterArgs["digits"]);
    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}
