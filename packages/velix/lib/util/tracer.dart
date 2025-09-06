
import 'package:stack_trace/stack_trace.dart';

enum TraceLevel { off, low, medium, high, full }

// internal
class TraceEntry {
  final String path;
  final TraceLevel level;
  final String message;
  final DateTime timestamp;
  final Frame? stackFrame;

  TraceEntry({
    required this.path,
    required this.level,
    required this.message,
    required this.stackFrame,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TraceModel {
  final String path;
  final String date;
  final String level;
  final String message;
  final String stackFrame;

  TraceModel({
    required this.path,
    required this.date,
    required this.level,
    required this.message,
   required this.stackFrame,
  });
}

typedef Renderer = void Function(StringBuffer builder, TraceModel model);

class TraceFormatter {
  final List<Renderer> _renderers;

  TraceFormatter(String format) : _renderers = _parse(format);

  String format(TraceEntry entry) {
    String frameInfo = '';
    if (entry.stackFrame != null) {
      final f = entry.stackFrame!;
      String path = entry.stackFrame!.uri.toString();

      if ( path.startsWith("package:")) {
        frameInfo = "$path:${f.line ?? 0}:${f.column ?? 0}";
      }
      else {
        final uri = entry.stackFrame!.uri;
        frameInfo =  '${uri.pathSegments.last}:${f.line ?? 0}:${f.column ?? 0} ';
      }
    }

    final model = TraceModel(
      path: entry.path,
      date: entry.timestamp.toIso8601String(),
      level: _levelToString(entry.level),
      message: entry.message,
      stackFrame: frameInfo
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
        case 'f':
          renderers.add((buf, model) => buf.write(model.stackFrame));
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

abstract class TraceSink {
  final TraceFormatter _formatter;

  TraceSink(dynamic formatter)
      : _formatter = (formatter is String)
      ? TraceFormatter(formatter)
      : formatter as TraceFormatter;

  void trace(TraceEntry entry);

  String format(TraceEntry entry) => _formatter.format(entry);
}

class ConsoleTrace extends TraceSink {
  ConsoleTrace(String messageFormat) : super(TraceFormatter(messageFormat));

  @override
  void trace(TraceEntry entry) {
    print(format(entry));
  }
}

class Tracer {
  static bool enabled = false;
  static Tracer? _instance;

  final Map<String, TraceLevel> _traceLevels = {};
  final Map<String, TraceLevel> _cachedTraceLevels = {};
  int _modifications = 0;
  final TraceSink? _trace;

  Tracer._internal({required TraceSink? trace, required bool isEnabled, Map<String, TraceLevel>? paths})
      : _trace = trace {
    enabled = isEnabled;
    paths?.forEach(setTraceLevel);
  }

  factory Tracer({TraceSink? trace, bool isEnabled = false, Map<String, TraceLevel>? paths}) =>
      _instance ??= Tracer._internal(trace: trace, isEnabled: isEnabled, paths: paths);

  static Tracer get instance => _instance ??= Tracer();

  static void trace(String path, TraceLevel level, String message, [List<dynamic> args = const []]) {
    final instance = Tracer.instance;
    if (!enabled || instance.getTraceLevel(path).index < level.index) return;

    final trace = Trace.current(1);
    final frame = trace.frames.isNotEmpty ? trace.frames.first : null;

    instance.doTrace(path, level, message, frame, args);
  }

  bool isTraced(String path, TraceLevel level) =>
      enabled && getTraceLevel(path).index >= level.index;

  Future<void> doTrace(String path, TraceLevel level, String message,  Frame? stackFrame, [dynamic args = const []]) async {
    if (isTraced(path, level)) {
      final formattedMessage = _formatMessage(message, args);
      _trace?.trace(TraceEntry(path: path, level: level, message: formattedMessage,  stackFrame: stackFrame));
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
