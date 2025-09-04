import 'package:intl/intl.dart';

import '../i18n.dart';

/// A [Formatter] that is able to format [DateTime]s with the format name "date"
/// Supported arguments are:
/// - String locale the desired locale, or if not supplied the current locale
/// - String pattern: a pattern according to the [DateFormat]
class DateFormatter extends Formatter {
  // constructor

  DateFormatter() : super("date");

  // override

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    var format = DateFormat(
        formatterArgs["pattern"],
        Formatter.locale(formatterArgs)
    );

    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}