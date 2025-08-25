
import 'package:intl/intl.dart';

import '../i18n.dart';

class DateFormatter extends Formatter {
  // instance data

  late DateFormat format;

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    format = DateFormat.yMd();
    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}