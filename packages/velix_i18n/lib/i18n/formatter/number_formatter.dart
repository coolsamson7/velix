import 'package:intl/intl.dart';

import '../i18n.dart';

/// A [Formatter] that is able to format numbers with the name "number".
/// Supported arguments are:
/// - String locale the desired locale, or if not supplied the current locale
/// - int minimumFractionDigits: minimum number of fraction digits
/// - int maximumFractionDigits: maximum number of fraction digits
class NumberFormatter extends Formatter {
  // constructor

  NumberFormatter() : super("number");

  // override

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    NumberFormat format = NumberFormat.decimalPattern(Formatter.locale(formatterArgs));

    if (formatterArgs["maximumFractionDigits"] != null)
      format.maximumFractionDigits = formatterArgs["maximumFractionDigits"];

    if (formatterArgs["minimumFractionDigits"] != null)
      format.minimumFractionDigits = formatterArgs["minimumFractionDigits"];

    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}

/// A [Formatter] that is able to format currency numbers with the name "currency".
/// Supported arguments are:
/// - String locale the desired locale, or if not supplied the current locale
/// - String name: the name of the currency
/// - int decimalDigits: the number of decimal digits
class CurrencyFormatter extends Formatter {
  // constructor

  CurrencyFormatter() : super("currency");

  // override

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    var format = NumberFormat.currency(
      locale: Formatter.locale(formatterArgs),
        name: formatterArgs["name"],
        decimalDigits: formatterArgs["decimalDigits"]
    );

    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}
