import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:intl/intl.dart';

class LruCache<K, V> {
  // instance data

  final int maxSize;
  final _cache = <K, V>{};

  // constructor

  LruCache(this.maxSize) {
    if (maxSize <= 0) {
      throw ArgumentError('maxSize must be > 0');
    }
  }

  // public

  V? get(K key) {
    if (!_cache.containsKey(key))
      return null;

    // Move key to the end to mark it as recently used
    final value = _cache.remove(key)!;
    _cache[key] = value;

    return value;
  }

  void set(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    else if (_cache.length >= maxSize) {
      // Remove the least recently used (first) entry
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void clear() => _cache.clear();

  @override
  String toString() => _cache.toString();
}


typedef I18NFunction = String Function(Map<String, dynamic> args);

abstract class Formatter {
  I18NFunction create(String variable, Map<String, dynamic> args);
}

class DateFormatter extends Formatter {
  // instance data

  late DateFormat format;

  @override
  I18NFunction create(String variable, Map<String, dynamic> formatterArgs) {
    var style = formatterArgs["style"];
    format = DateFormat.yMd();
    return (Map<String, dynamic> args) => format.format(args[variable]);
  }
}

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

class Interpolator {
  // instance data

  LruCache<String, I18NFunction> _cache = LruCache<String, I18NFunction>(50); // ?

  Map<String,Formatter> formatter = {
    "number": NumberFormatter(),
    "currency": CurrencyFormatter(),
    "date": DateFormatter()
  };

  RegExp variablePattern =  RegExp(r'^{(?<variable>\w+)}$');
  RegExp variableFormatPattern = RegExp(r'^{(?<variable>\w+)\s*:\s*(?<format>\w+)}$');
  RegExp variableFormatArgsPattern = RegExp(r"^{(?<variable>\w+)\s*:\s*(?<format>\w+)\((?<parameters>[\d: ,a-zA-Z']+)\)}$");

  RegExp paramPattern = RegExp(r"\s*(?<parameter>\w+)\s*:\s*(?<value>-?\d+|true|false|\'\w+\')");

  final regex = RegExp(r'\{[^}]+\}');

  // internal

  I18NFunction parsePlaceholder(String placeholder) {
    // variable

    var match = variablePattern.firstMatch(placeholder);
    if ( match != null) {
      final variable = match.namedGroup('variable');

      return (Map<String, dynamic> args) => args[variable].toString();
    }

    // variable:formatter

    match = variableFormatPattern.firstMatch(placeholder);

    if ( match != null) {
      final variable = match.namedGroup('variable')!;
      final format = match.namedGroup('format')!;

      return formatter[format]!.create(variable, {});
    }

    // variable:formatter(args)

    void parseParam(String param, Map<String, dynamic> parameters) {
      final match = paramPattern.firstMatch(param);

      if (match != null) {
        final parameter = match.namedGroup('parameter')!;
        final valueStr = match.namedGroup('value')!;

        // convert value to proper type
        dynamic value;
        if (valueStr == 'true' || valueStr == 'false') {
          value = valueStr == 'true';
        }
        else if (valueStr!.startsWith("'") && valueStr.endsWith("'")) {
          value = valueStr.substring(1, valueStr.length - 1);
        }
        else {
          value = int.parse(valueStr);
        }

        parameters[parameter] = value;
      } // if
    }

    match = variableFormatArgsPattern.firstMatch(placeholder);
    if ( match != null) {
      Map<String, dynamic> params = {};

      final variable = match.namedGroup('variable')!;
      final format = match.namedGroup('format')!;
      final parameters = match.namedGroup('parameters')!;

      int start = 0;
      int index = parameters.indexOf(",");
      var parameter = "";
      while ( index > 0) {
        var parameter = parameters.substring(start, index).trim();

        parseParam(parameter, params);

        start += parameter.length + 1;
        index = parameters.indexOf(",", start);
      }

      // last

      parameter = parameters.substring(start).trim();

      parseParam(parameter, params);

      // done

      return formatter[format]!.create(variable, params);
    } // if

    // nada

    throw Exception("syntax error");
  }

  // public

  I18NFunction get(String input) {
    I18NFunction? result = _cache.get(input);
    if ( result == null) {
      _cache.set(input, result = parse(input));
    }

    return result;
  }

  I18NFunction parse(String input) {
    final parts = <dynamic>[];

    var last = 0;
    for (final match in regex.allMatches(input)) {
      // Literal before placeholder
      if (match.start > last) {
        final literal = input.substring(last, match.start);
        if (literal.isNotEmpty) parts.add(literal);
      }

      // Placeholder

      parts.add(parsePlaceholder(match.group(0)!));
      last = match.end;
    }

    // Trailing literal

    if (last < input.length) {
      parts.add(input.substring(last));
    }

    // Merge adjacent literals

    final merged = <dynamic>[];
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is String) {
        buffer.write(part);
      }
      else {
        if (buffer.isNotEmpty) {
          merged.add(buffer.toString());
          buffer.clear();
        }
        merged.add(part);
      }
    }
    if (buffer.isNotEmpty)
      merged.add(buffer.toString());

    // final function

    return (Map<String, dynamic> args) {
      final out = StringBuffer();
      for (final part in merged) {
        if (part is String) {
          out.write(part);
        }
        else {
          out.write(part(args));
        }
      }

      return out.toString();
    };
  }
}


typedef MissingKeyHandler = String Function(String key);

/// A `LocaleManager` 
class LocaleManager {
  // instance data
  
  final ValueNotifier<Locale> _currentLocale;

  // constructor
  
  LocaleManager(Locale initialLocale) : _currentLocale = ValueNotifier(initialLocale);

  // public

  Locale get locale => _currentLocale.value;

  set locale(Locale value) => _currentLocale.value = value;

  void addListener(VoidCallback listener) {
    _currentLocale.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    _currentLocale.removeListener(listener);
  }
}

/// A `TranslationLoader` loads translations.

abstract class TranslationLoader {
  Future<Map<String, dynamic>> load(Locale locale, String namespace);
}

class AssetTranslationLoader implements TranslationLoader {
  // instance data

  final String basePath;

  // constructor

  /// [basePath] is the folder where your locales live, e.g. 'assets/locales'
  AssetTranslationLoader({this.basePath = 'assets/locales'});

  // override

  @override
  Future<Map<String, dynamic>> load(Locale locale, String namespace) async {
    final path = '$basePath/${locale.languageCode}/$namespace.json';

    try {
      final jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> map = json.decode(jsonString);
      return map;
    }
    catch (e) {
      // Could not load the file; return empty map or handle missing file
      debugPrint('Translation file not found: $path, error: $e');
      return {};
    }
  }
}
///  I18n Core
class I18n {
  // static data

  static late I18n instance;

  // instance data

  final LocaleManager _localeManager;
  final TranslationLoader _loader;
  final MissingKeyHandler? _missingKeyHandler;

  Map<String, Map<String, dynamic>> _namespaces = {};

  late VoidCallback _localeListener;

  Interpolator interpolator = Interpolator();

  // constructor

  I18n({
    required LocaleManager localeManager,
    required TranslationLoader loader,
    MissingKeyHandler? missingKeyHandler,
  })
      : _localeManager = localeManager,
        _loader = loader,
        _missingKeyHandler = missingKeyHandler {
    instance = this;

    _localeListener = () => _reloadTranslations();
    _localeManager.addListener(_localeListener);
  }

  // internal

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

  (String namespace, String path) extractNamespace(String key) {
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
    final futures = _namespaces.keys.map((ns) => _loadTranslations(ns).catchError((e) { /* TODO */}));

    await Future.wait(futures);
  }

  Future<void> _loadTranslations(String namespace) async {
    final locale = _localeManager.locale;
    _namespaces[namespace] = await _loader.load(locale, namespace);
  }

  String interpolate(String template, {Map<String, dynamic>? args}) {
    return interpolator.get(template)(args ?? {});
  }

  // public

  Future<void> loadNamespaces(List<String> namespaces) async {
    final futures = namespaces
        .where((ns) => !isLoaded(ns))
        .map((ns) => _loadTranslations(ns));

    // wait for all of them in parallel

    await Future.wait(futures);
  }

  String translate(String key, {Map<String, dynamic>? args}) {
    var (namespace, path) = extractNamespace(key);

    if (!isLoaded(namespace)) {
      _loadTranslations(namespace);
      return _missingKeyHandler!(key);
    }

    var value = get(_namespaces[namespace], path);

    if (value != null) {
      return interpolate(value, args: args);
    }
    else
      return _missingKeyHandler!(key);
  }

  void dispose() {
    _localeManager.removeListener(_localeListener);
  }

  Future<String> translateAsync(String key,
      {Map<String, dynamic>? args}) async {
    var (namespace, path) = extractNamespace(key);

    if (!isLoaded(namespace)) {
      await _loadTranslations(namespace);
    }

    var value = get(_namespaces[namespace], path);

    if (value != null) {
      return interpolate(value, args: args);
    }
    else
      return _missingKeyHandler!(key);
  }
}

// extension

extension I18nStringExtension on String {
  String tr(Map<String, dynamic>? args) {
    return I18n.instance.translate(this, args: args);
  }
}