import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:velix/util/ordered_async_value_notifier.dart';
import 'interpolator.dart';
import 'locale.dart';

typedef I18NFunction = String Function(Map<String, dynamic> args);

/// a [Formatter] is used to format placeholders.
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

  /// create a new [Formatter]
  /// [name] the name
  Formatter(this.name);

  // abstract

  /// create the [I18NFunction] that will execute the formatting.
  /// [variable] the placeholder variable which will be formatted
  I18NFunction create(String variable, Map<String, dynamic> args);
}

/// function used to compute a localization in case of missing i18n data
typedef MissingKeyHandler = String Function(String key);


/// A `TranslationLoader` loads translations.

abstract class TranslationLoader {
  /// load translations given a namespace and a list of locales
  /// [locales] list of [Locale]s that determine the overall result. Starting with the first locale, teh resulting map is computed, the following locales will act as fallbacks, in case of missing keys.
  Future<Map<String, dynamic>> load(List<Locale> locales, String namespace);
}

class I18NState {
  I18N? i18n;

  I18NState({required this.i18n});
}

///  I18n is a central singleton that controls the overall localization process.
class I18N extends OrderedAsyncValueNotifier<I18NState> {
  // static data

  /// the singleton instance
  static late I18N instance;

  // instance data

  final LocaleManager _localeManager;
  final TranslationLoader _loader;
  final MissingKeyHandler? _missingKeyHandler;
  final Map<String, Map<String, dynamic>> _namespaces = {};
  final Interpolator _interpolator;
  final Locale? fallbackLocale;

  List<Locale> locales = [];

  Locale get locale => _localeManager.locale;

  // constructor

  /// Create a new [I18N]
  /// [localeManager] the [LocaleManager] the tracks the current locale
  /// [loader] a [TranslationLoader] instance used for loading localizations
  /// [missingKeyHandler] a function that will return a localization result in case of missing data
  /// [fallbackLocale] a optional [Locale] that is used to retrieve results in cases of a miss using the main locale
  /// [preloadNamespaces] optional list of namespaces that should be preloaded on application startup
  /// [formatters] optional list of additional [Formatter]s that can be used for interpolating placeholders
  /// [cacheSize] size of the interpolator cache, remembering computed interpolation functions.
  I18N({
    required LocaleManager localeManager,
    required TranslationLoader loader,
    MissingKeyHandler? missingKeyHandler,
    this.fallbackLocale,
    List<String>? preloadNamespaces,
    List<Formatter>? formatters,
    int cacheSize = 50
  })
      :_interpolator = Interpolator(cacheSize: cacheSize, formatters: formatters),
        _localeManager = localeManager,
        _loader = loader,
        _missingKeyHandler = missingKeyHandler , super(I18NState(i18n: null)){
    instance = this;

    localeManager.addListener(() => load());

    // remember preload namespaces

    if ( preloadNamespaces != null)
      for ( var preload in  preloadNamespaces)
        _namespaces[preload] = {};

    locales = _buildFallbackLocales(locale, fallbackLocale);
  }

  // internal

  List<Locale> _buildFallbackLocales(Locale locale, Locale? fallback) {
    final fallbackLocales = <Locale>[];

    maybeAdd(Locale locale)  {
      if (!fallbackLocales.contains(locale))
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

  bool isMap(dynamic entry) {
    return entry.runtimeType.toString().contains("Map");
  }

  T? get<T>(dynamic object, String key, [T? defaultValue]) {
    final path = key.split('.');
    var current = object;

    for (final segment in path) {
      if (/*isMap(current) &&*/ current.containsKey(segment)) {
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

  /// return [true] if a specified namespace is already loaded
  /// [namespace] a namespace
  bool isLoaded(String namespace) {
    return _namespaces[namespace] != null;
  }

  Future<void> load() async {
    locales = _buildFallbackLocales(locale, fallbackLocale);
    final futures = _namespaces.keys.map((ns) => _loadTranslations(ns, locales).catchError((e) { /* TODO */}));

    await Future.wait(futures);

    await updateValue(I18NState(i18n: this));
  }

  Future<void> _loadTranslations(String namespace, List<Locale> locales) async {
    _namespaces[namespace] = await _loader.load(locales, namespace);
  }

  String interpolate(String template, {Map<String, dynamic>? args}) {
    return _interpolator.get(template)(args ?? {});
  }

  // public

  /// return the list of supported locales
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

  /// translate a key
  /// [key] a key
  /// [args] any parameters that may be used for interpolation
  String translate(String key, {String? defaultValue, Map<String, dynamic>? args}) {
    var (namespace, path) = _extractNamespace(key);

    if (!isLoaded(namespace)) {
      _loadTranslations(namespace, locales);

      return defaultValue ?? _missingKeyHandler!(key);
    }

    var value = get(_namespaces[namespace], path);

    if (value != null) {
      return interpolate(value, args: args);
    }
    else
      return defaultValue ?? _missingKeyHandler!(key);
  }

  /// translate a key async and wait for the result in case of missing namespaces
  /// [key] a key
  /// [args] any parameters that may be used for interpolation
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

/// A specialized [LocalizationsDelegate] that will load all necessary localizations
class I18nDelegate extends LocalizationsDelegate<I18N> {
  // instance data

  I18N i18n;

  // constructor

  /// Create a new [I18nDelegate]
  /// [i18n] the [I18N] instance
  I18nDelegate({required this.i18n});

  // override

  @override
  bool isSupported(Locale locale) => i18n.supportedLocales().contains(locale);

  @override
  Future<I18N> load(Locale locale) async {
    await i18n.load();

    return i18n;
  }

  @override
  bool shouldReload(LocalizationsDelegate<I18N> old) => false;
}

// extension

/// extension on string sm which allows a `tr()` function call
extension I18nStringExtension on String {
  String tr([Map<String, dynamic>? args]) {
    return I18N.instance.translate(this, args: args);
  }
}