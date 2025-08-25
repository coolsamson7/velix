
import '../util/collections.dart';
import 'formatter/date_formatter.dart';
import 'formatter/number_formatter.dart';
import 'i18n.dart';

class Interpolator {
  // instance data

  final LruCache<String, I18NFunction> _cache;

  final Map<String,Formatter> _formatter = {
    "number": NumberFormatter(),
    "currency": CurrencyFormatter(),
    "date": DateFormatter()
  };

  final regex = RegExp(r'\{[^}]+\}');
  final placeholderPattern = RegExp(
      r'^{(?<variable>\w+)(?::(?<format>\w+)(?:\((?<params>[^)]*)\))?)?}$'
  );
  final paramPattern = RegExp(r'\s*(\w+)\s*:\s*([^,]+)\s*');

  // constructor

  Interpolator({int cacheSize = 50, List<Formatter>? formatters}) : _cache = LruCache<String, I18NFunction>(cacheSize) {
    if ( formatters != null)
      for ( var formatter in formatters)
        _formatter[formatter.name] = formatter;
  }

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

      return _formatter[format]!.create(variable, evaluated)(args);
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