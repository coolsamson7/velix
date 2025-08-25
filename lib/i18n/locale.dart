import 'dart:ui';
import 'package:flutter/foundation.dart';

import '../util/tracer.dart';

List<Locale> empty_locales = [];

/// A `LocaleManager`
class LocaleManager extends ChangeNotifier {
  // instance data

  Locale _currentLocale;
  List<Locale> supportedLocales;

  // constructor

  LocaleManager(this._currentLocale, {List<Locale>? supportedLocales }) : supportedLocales = supportedLocales ?? [];

  // public

  Locale get locale => _currentLocale;

  set locale(Locale value) {
    if ( value != _currentLocale) {
      Tracer.trace("i18n", TraceLevel.high, "set locale $value");

      _currentLocale = value;
      notifyListeners();
    }
  }
}