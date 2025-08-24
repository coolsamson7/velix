enum TraceLevel { off, low, medium, high, full }

class TraceEntry {
  final String path;
  final TraceLevel level;
  final String message;
  final DateTime timestamp;

  TraceEntry({
    required this.path,
    required this.level,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TraceModel {
  final String path;
  final String date;
  final String level;
  final String message;

  TraceModel({
    required this.path,
    required this.date,
    required this.level,
    required this.message,
  });
}

typedef Renderer = void Function(StringBuffer builder, TraceModel model);

class TraceFormatter {
  final List<Renderer> _renderers;

  TraceFormatter(String format) : _renderers = _parse(format);

  String format(TraceEntry entry) {
    final model = TraceModel(
      path: entry.path,
      date: entry.timestamp.toIso8601String().split('T').first,
      level: _levelToString(entry.level),
      message: entry.message,
    );

    return _build(model);
  }

  static String _levelToString(TraceLevel level) {
    return level.toString().split('.').last.toUpperCase();
  }

  static List<Renderer> _parse(String format) {
    final List<Renderer> renderers = [];

    int lastIndex = 0;
    final length = format.length;

    while (true) {
      final percentIndex = format.indexOf('%', lastIndex);
      if (percentIndex == -1 || percentIndex + 1 >= length) {
        if (lastIndex < length) {
          final text = format.substring(lastIndex);
          renderers.add((buf, model) => buf.write(text));
        }
        break;
      }

      // Add text before % as literal
      if (percentIndex > lastIndex) {
        final text = format.substring(lastIndex, percentIndex);
        renderers.add((buf, model) => buf.write(text));
      }

      final specifier = format[percentIndex + 1];
      switch (specifier) {
        case 'd':
          renderers.add((buf, model) => buf.write(model.date));
          break;
        case 'l':
          renderers.add((buf, model) => buf.write(model.level));
          break;
        case 'p':
          renderers.add((buf, model) => buf.write(model.path));
          break;
        case 'm':
          renderers.add((buf, model) => buf.write(model.message));
          break;
        default:
        // Treat unknown specifiers as literal text
          renderers.add((buf, model) => buf.write('%$specifier'));
          break;
      }

      lastIndex = percentIndex + 2;
    }

    return renderers;
  }

  String _build(TraceModel model) {
    final buffer = StringBuffer();

    for (final render in _renderers) {
      render(buffer, model);
    }

    return buffer.toString();
  }
}

abstract class Trace {
  final TraceFormatter _formatter;

  Trace(dynamic formatter)
      : _formatter = (formatter is String)
      ? TraceFormatter(formatter)
      : formatter as TraceFormatter;

  void trace(TraceEntry entry);

  String format(TraceEntry entry) => _formatter.format(entry);
}

class ConsoleTrace extends Trace {
  ConsoleTrace(String messageFormat) : super(TraceFormatter(messageFormat));

  @override
  void trace(TraceEntry entry) {
    print(format(entry));
  }
}

class Tracer {
  static bool enabled = true;
  static Tracer? _instance;

  final Map<String, TraceLevel> _traceLevels = {};
  final Map<String, TraceLevel> _cachedTraceLevels = {};
  int _modifications = 0;
  final Trace? _trace;

  Tracer._internal({required Trace? trace, required bool isEnabled, Map<String, TraceLevel>? paths})
      : _trace = trace {
    enabled = isEnabled;
    paths?.forEach(setTraceLevel);
  }

  factory Tracer({Trace? trace, bool isEnabled = true, Map<String, TraceLevel>? paths}) =>
      _instance ??= Tracer._internal(trace: trace, isEnabled: isEnabled, paths: paths);

  static Tracer get instance => _instance ??= Tracer();

  static void trace(String path, TraceLevel level, String message, [List<dynamic> args = const []]) {
    final instance = Tracer.instance;
    if (!enabled || instance.getTraceLevel(path).index < level.index) return;

    instance.doTrace(path, level, message, args);
  }

  bool isTraced(String path, TraceLevel level) =>
      enabled && getTraceLevel(path).index >= level.index;

  Future<void> doTrace(String path, TraceLevel level, String message, [dynamic args = const []]) async {
    if (isTraced(path, level)) {
      final formattedMessage = _formatMessage(message, args);
      _trace?.trace(TraceEntry(path: path, level: level, message: formattedMessage));
    }
  }

  TraceLevel getTraceLevel(String path) {
    if (_modifications > 0) {
      _cachedTraceLevels.clear();
      _modifications = 0;
    }

    return _cachedTraceLevels.putIfAbsent(path, () {
      final level = _traceLevels[path] ??
          (path.contains('.') ? getTraceLevel(path.substring(0, path.lastIndexOf('.'))) : TraceLevel.off);
      return level;
    });
  }

  void setTraceLevel(String path, TraceLevel level) {
    _traceLevels[path] = level;
    _modifications++;
  }

  String _formatMessage(String message, dynamic args) {
    final List<dynamic> argList = args is List ? args : [args];
    return message.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
      final index = int.tryParse(match.group(1) ?? '-1')!;
      return (index >= 0 && index < argList.length) ? '${argList[index] ?? "null"}' : match.group(0)!;
    });
  }
}
