import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:velix/util/tracer.dart';

/// A [LocaleManager] keeps track of the current locale abd can notify listeners about changes,.
class LocaleManager extends ChangeNotifier {
  // instance data

  Locale _currentLocale;
  List<Locale> supportedLocales;

  // constructor

  /// Create a new [LocaleManager]
  /// [locale] the initial locale
  /// [supportedLocales] optional list of supported locales
  LocaleManager(Locale locale, {List<Locale>? supportedLocales }) : _currentLocale = locale, supportedLocales = supportedLocales ?? [] {
    Intl.defaultLocale = _currentLocale.toString();
}

  // public

  Locale get locale => _currentLocale;

  set locale(Locale value) {
    if ( value != _currentLocale) {
      if ( Tracer.enabled)
        Tracer.trace("i18n", TraceLevel.high, "set locale $value");

      _currentLocale = value;

      Intl.defaultLocale = _currentLocale.toString();

      notifyListeners();
    }
  }
}