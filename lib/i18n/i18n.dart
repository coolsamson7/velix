import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'interpolator.dart';
import 'locale.dart';

typedef I18NFunction = String Function(Map<String, dynamic> args);


abstract class Formatter {
  // static

  static String locale(Map<String, dynamic> args) {
    var locale = args["locale"];
    if ( locale is String)
      return locale;

    else if ( locale is Locale)
      return locale.toString();

    else return Intl.defaultLocale ?? "en";
  }

  // instance data

  String name;

  // constructor

  Formatter(this.name);

  // abstract

  I18NFunction create(String variable, Map<String, dynamic> args);
}

typedef MissingKeyHandler = String Function(String key);


/// A `TranslationLoader` loads translations.

abstract class TranslationLoader {
  Future<Map<String, dynamic>> load(List<Locale> locales, String namespace);
}

///  I18n Core
class I18N {
  // static data

  static late I18N instance;

  // instance data

  final LocaleManager _localeManager;
  final TranslationLoader _loader;
  final MissingKeyHandler? _missingKeyHandler;
  final Map<String, Map<String, dynamic>> _namespaces = {};
  final Interpolator _interpolator;
  final List<String>? preloadNamespaces;
  final Locale? fallbackLocale;

  List<Locale> locales = [];

  Locale get locale => _localeManager.locale;

  // constructor

  I18N({
    required LocaleManager localeManager,
    required TranslationLoader loader,
    MissingKeyHandler? missingKeyHandler,
    this.preloadNamespaces,
    this.fallbackLocale,
    List<Formatter>? formatters,
    int cacheSize = 50
  })
      :_interpolator = Interpolator(cacheSize: cacheSize, formatters: formatters),
        _localeManager = localeManager,
        _loader = loader,
        _missingKeyHandler = missingKeyHandler {
    instance = this;

    // remember preload namespaces

    if ( preloadNamespaces != null)
      for ( var preload in  preloadNamespaces!)
        _namespaces[preload] = {};
  }

  // internal

  List<Locale> _buildFallbackLocales(Locale locale, Locale? fallback) {
    final fallbackLocales = <Locale>[];

    maybeAdd(Locale locale)  {
      if (fallbackLocales.contains(locale))
        fallbackLocales.add(locale);
    }

    // Start with exact locale, e.g. de_DE

    fallbackLocales.add(locale);

    // Then fallback to language only e.g. de

    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      maybeAdd(Locale(locale.languageCode));
    }

    // add explicit fallbacks

    if ( fallback != null) {
      maybeAdd(fallback);

      if (fallback.countryCode != null && fallback.countryCode!.isNotEmpty) {
        maybeAdd(Locale(fallback.languageCode));
      }
    }

    return fallbackLocales;
  }

  T? get<T>(dynamic object, String key, [T? defaultValue]) {
    final path = key.split('.');
    var current = object;

    for (final segment in path) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      }
      else {
        return defaultValue;
      }
    }

    return current is T ? current : defaultValue;
  }

  (String namespace, String path) _extractNamespace(String key) {
    final colonIndex = key.indexOf(':');

    if (colonIndex > 0) {
      return (
      key.substring(0, colonIndex),
      key.substring(colonIndex + 1),
      );
    }
    else {
      return ('', key);
    }
  }

  bool isLoaded(String namespace) {
    return _namespaces[namespace] != null;
  }

  Future<void> _reloadTranslations() async {
    locales = _buildFallbackLocales(locale, fallbackLocale);
    final futures = _namespaces.keys.map((ns) => _loadTranslations(ns, locales).catchError((e) { /* TODO */}));

    await Future.wait(futures);
  }

  Future<void> _loadTranslations(String namespace, List<Locale> locales) async {
    _namespaces[namespace] = await _loader.load(locales, namespace);
  }

  String interpolate(String template, {Map<String, dynamic>? args}) {
    return _interpolator.get(template)(args ?? {});
  }

  // public

  List<Locale> supportedLocales() {
    return _localeManager.supportedLocales;
  }

  Future<void> loadNamespaces(List<String> namespaces) async {
    final futures = namespaces
        .where((ns) => !isLoaded(ns))
        .map((ns) => _loadTranslations(ns, locales));

    // wait for all of them in parallel

    await Future.wait(futures);
  }

  String translate(String key, {Map<String, dynamic>? args}) {
    var (namespace, path) = _extractNamespace(key);

    if (!isLoaded(namespace)) {
      _loadTranslations(namespace, locales);
      return _missingKeyHandler!(key);
    }

    var value = get(_namespaces[namespace], path);

    if (value != null) {
      return interpolate(value, args: args);
    }
    else
      return _missingKeyHandler!(key);
  }

  Future<String> translateAsync(String key, {Map<String, dynamic>? args}) async {
    var (namespace, path) = _extractNamespace(key);

    if (!isLoaded(namespace)) {
      await _loadTranslations(namespace, locales);
    }

    var value = get(_namespaces[namespace], path);

    if (value != null) {
      return interpolate(value, args: args);
    }
    else
      return _missingKeyHandler!(key);
  }
}

// delegate
class I18nDelegate extends LocalizationsDelegate<I18N> {
  // instance data

  I18N i18n;

  // constructor

  I18nDelegate({required this.i18n});

  // override

  @override
  bool isSupported(Locale locale) => i18n.supportedLocales().contains(locale);

  @override
  Future<I18N> load(Locale locale) async {
    await i18n._reloadTranslations();

    return i18n;
  }

  @override
  bool shouldReload(LocalizationsDelegate<I18N> old) => false;
}

// extension

extension I18nStringExtension on String {
  String tr([Map<String, dynamic>? args]) {
    return I18N.instance.translate(this, args: args);
  }
}