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

  LruCache<String, I18NFunction> _cache;

  Map<String,Formatter> formatter = {
    "number": NumberFormatter(),
    "currency": CurrencyFormatter(),
    "date": DateFormatter()
  };

  final regex = RegExp(r'\{[^}]+\}'); // RegExp(r'\{[^{}]*\}');//
  final placeholderPattern = RegExp(
      r'^{(?<variable>\w+)(?::(?<format>\w+)(?:\((?<params>[^)]*)\))?)?}$'
  );
  final paramPattern = RegExp(r'\s*(\w+)\s*:\s*([^,]+)\s*');

  // constructor

  Interpolator({int cacheSize = 50}) : _cache = LruCache<String, I18NFunction>(cacheSize);

  // internal

  I18NFunction _parsePlaceholder(String placeholder) {
    final match = placeholderPattern.firstMatch(placeholder);
    if (match == null)
      throw Exception("syntax error: $placeholder");

    final variable = match.namedGroup('variable')!;
    final format = match.namedGroup('format');
    final paramStr = match.namedGroup('params');

    // {variable}

    if (format == null) {
      return (args) => args[variable]?.toString() ?? "";
    }

    // Params are parsed once into raw map (strings, ints, bools, or I18NFunction)

    final rawParams = _parseParams(paramStr);

    // Return composed function:
    // At render time, eval any I18NFunction params

    return (args) {
      final evaluated = <String, dynamic>{};

      for (final entry in rawParams.entries) {
        final val = entry.value;
        if (val is I18NFunction) {
          evaluated[entry.key] = val(args); // dynamic placeholder
        }
        else {
          evaluated[entry.key] = val;
        }
      }

      // Formatter returns a function → call with args immediately

      return formatter[format]!.create(variable, evaluated)(args);
    };
  }

  Map<String, dynamic> _parseParams(String? paramStr) {
    if (paramStr == null)
      return {};

    final params = <String, dynamic>{};

    for (final match in paramPattern.allMatches(paramStr)) {
      final key = match.group(1)!;
      final raw = match.group(2)!;

      params[key] = _parseValue(raw);
    }

    return params;
  }

  dynamic _parseValue(String raw) {
    // Placeholder? → compile to I18NFunction

    if (raw.startsWith(r'$')) {
      final varName = raw.substring(1);
      return (Map<String, dynamic> args) => args[varName]?.toString() ?? '';
    }

    // boolean

    if (raw == 'true' || raw == 'false')
      return raw == 'true';

    // quoted string

    if (raw.startsWith("'") && raw.endsWith("'")) {
      return raw.substring(1, raw.length - 1);
    }

    // integer

    final intVal = int.tryParse(raw);
    if (intVal != null)
      return intVal;

    // fallback

    return raw;
  }

  // public

  I18NFunction parse(String input) {
    final parts = <dynamic>[];

    var last = 0;
    for (final match in regex.allMatches(input)) {
      // literal before placeholder

      if (match.start > last) {
        final literal = input.substring(last, match.start);
        if (literal.isNotEmpty)
          parts.add(literal);
      }

      // placeholder

      parts.add(_parsePlaceholder(match.group(0)!));
      last = match.end;
    }

    // trailing literal

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
    } // for

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

  // public

  I18NFunction get(String input) {
    I18NFunction? result = _cache.get(input);
    if ( result == null) {
      _cache.set(input, result = parse(input));
    }

    return result;
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