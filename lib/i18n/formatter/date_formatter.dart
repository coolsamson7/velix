
import 'dart:ui';

import 'package:intl/intl.dart';

import '../i18n.dart';

class DateFormatter extends Formatter {
  // override

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    var format = DateFormat(
        formatterArgs["pattern"],
        locale(formatterArgs)
    );

    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}