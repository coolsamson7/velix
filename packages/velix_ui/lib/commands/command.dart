import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

import 'package:velix/i18n/translator.dart';

/// enum specifying how execution of a command will influence the ui state
enum LockType {
  /// the command is disabled while executing
  command,
  /// the associated [CommandView] is disabled while executing
  view,
  /// ...
  group;
}

/// decorates methods that should be exposed as commands.
class Command {
  // instance data

  final String? name;
  final String? i18n;
  final String? label;
  final LockType lock;
  final IconData? icon;

  // constructor

  const Command({this.name, this.label, this.i18n, this.icon, this.lock = LockType.command});
}

class CommandException implements Exception {
  final String message;

  CommandException(this.message);

  @override
  String toString() => 'CommandException: $message';
}

/// Internal representation of a command, including all interceptors
class CommandDescriptor extends ChangeNotifier {
  // instance data

  final String name;
  final String? i18n;
  late String? label;
  late String? shortcut;
  late String? tooltip;
  late IconData? icon;
  final LockType lock;
  final List<CommandInterceptor> _interceptors = [];
  late Function function;
  bool _enabled = true;

  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;

      notifyListeners();
    }
  }

  // constructor

  CommandDescriptor({required this.name, required this.function, this.i18n, this.label, this.icon, this.shortcut, this.tooltip, this.lock = LockType.command});

  // administrative

  void addInterceptor(CommandInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  void prependInterceptor(CommandInterceptor interceptor) {
    _interceptors.insert(0, interceptor);
  }

  // public

  /// Always returns a Future, regardless of whether the function is sync or async
  Future<dynamic> execute([List<dynamic> args = const []]) async {
    final invocation = Invocation(command: this, args: args);

    FutureOr<dynamic> callNext(int index) {
      return _interceptors[index](invocation, () => callNext(index + 1));
    }

    // Ensure the return type is a Future
    return await Future.sync(() => callNext(0));
  }
}

/// Covers the parameters of a command invocation:
/// - the command name
/// - the args
class Invocation {
  // instance data

  final CommandDescriptor command;
  List<dynamic> args;

  // constructor

  /// Create a new [Invocation]
  /// [command] the command name
  /// [args] the supplied args
  Invocation({required this.command, required this.args});
}

/// Base class for command interceptors.
abstract class CommandInterceptor {
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next);
}

/// A simple [CommandInterceptor] that traces command invocations on stdout
class TracingCommandInterceptor implements CommandInterceptor {
  @override
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next) async {
    print("> ${invocation.command.name}");
    try {
      return await Future.value(next!());
    }
    finally {
      print("< ${invocation.command.name}");
    }
  }
}

/// A [CommandInterceptor] that disables a command while being executed.
class LockCommandInterceptor implements CommandInterceptor {
  @override
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next) async {
    bool enabled = invocation.command.enabled;
    try {
      invocation.command.enabled = false;

      return await Future.value(next!());
    }
    finally {
      invocation.command.enabled = enabled;
    }
  }
}

/// @internal
class MethodCommandInterceptor implements CommandInterceptor {
  @override
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next) {
    return Future.value(Function.apply(invocation.command.function, invocation.args));
  }
}

/// Central class that controls the creation of [CommandInterceptor]s for commands
/// @internal
class CommandManager {
  // instance data

  MethodCommandInterceptor methodInterceptor = MethodCommandInterceptor();
  List<CommandInterceptor> interceptors = [];

  // constructor

  CommandManager({this.interceptors = const []});

  // public

  CommandDescriptor createCommand(String name, Function function, {String? i18n, String? label, IconData? icon, LockType lock = LockType.command}) {
    if ( label == null) {
      if (i18n != null) {
        label = Translator.tr("$i18n.label");
      }
      else {
        label = name;
      }
    }

    var shortcut = "";
    var tooltip = "";

    if ( i18n != null) {
      shortcut = Translator.tr("$i18n.shortcut", defaultValue: "");
      tooltip = Translator.tr("$i18n.tooltip", defaultValue: "");
    }

    CommandDescriptor command = CommandDescriptor(name: name, function: function, i18n: i18n, shortcut: shortcut, tooltip: tooltip, label: label, icon: icon, lock: lock);

    // add standard interceptors

    for ( CommandInterceptor interceptor in interceptors)
      command.addInterceptor(interceptor);

    // the method itself

    command.addInterceptor(methodInterceptor);

    return command;
  }
}

class CommandIntent extends Intent {
  final CommandDescriptor command;
  const CommandIntent(this.command);
}

class CommandAction extends Action<CommandIntent> {
  @override
  Object? invoke(CommandIntent intent) {
    return intent.command.execute();
  }
}

LogicalKeySet? parseShortcut(String shortcut) {
  final parts = shortcut.toLowerCase().split('+').map((s) => s.trim()).toList();

  final keys = <LogicalKeyboardKey>[];

  for (var part in parts) {
    switch (part) {
      case 'ctrl':
      case 'control':
        keys.add(LogicalKeyboardKey.control);
        break;
      case 'shift':
        keys.add(LogicalKeyboardKey.shift);
        break;
      case 'alt':
        keys.add(LogicalKeyboardKey.alt);
        break;
      case 'meta':
      case 'cmd':
      case 'command':
        keys.add(LogicalKeyboardKey.meta);
        break;
      default:
        final letter = part.toUpperCase();
        if (letter.length == 1) {
          keys.add(LogicalKeyboardKey(letter.codeUnitAt(0)));
        } else {
          // fallback: try lookup by name
          final key = LogicalKeyboardKey.findKeyByKeyId(letter.hashCode);
          if (key != null) keys.add(key);
        }
    }
  }

  if (keys.isEmpty) return null;
  return LogicalKeySet.fromSet(keys.toSet());
}

/// Mixin class that adds the ability to handle commands
mixin CommandController<T extends StatefulWidget> on State<T> {
  // instance data

  final Map<String, CommandDescriptor> _commands = {};
  late CommandManager commandManager;

  // public

  Map<ShortcutActivator, Intent> computeShortcuts() {
    return {
      for (var cmd in getCommands())
        if (cmd.shortcut != null && parseShortcut(cmd.shortcut!) != null)
          parseShortcut(cmd.shortcut!)! : CommandIntent(cmd),
    };
  }

  /// @internal
  List<CommandDescriptor> getCommands() {
    return _commands.values.toList();
  }

  /// @internal
  void addCommand(String name, Function function, {String? label, String? i18n, IconData? icon, LockType? lock}) {
    _commands[name] = commandManager.createCommand(name, function, i18n: i18n, label: label, icon: icon, lock: lock ?? LockType.command);
  }

  /// @internal
  CommandDescriptor getCommand(String name) {
    CommandDescriptor? command = _commands[name];
    if (command != null) {
      return command;
    }
    else {
      throw CommandException("unknown command '$name'");
    }
  }

  /// enable or disable a named command
  /// [command] the command name
  /// [enabled] the enabled status
  void setCommandEnabled(String command, bool enabled) {
    getCommand(command).enabled = enabled;
  }

  /// return [true],  if the named command is enabled
  /// [command] the command name
  bool isCommandEnabled(String command) {
    return getCommand(command).enabled ;
  }

  Future<dynamic> execute(String name, List<dynamic> args) {
    return getCommand(name).execute(args);
  }

  /// @internal
  void initCommands() {}

  /// update the command states
  void updateCommandState() {}

  // override

  @override
  void initState() {
    super.initState();

    commandManager = context.read<CommandManager>();

    initCommands();
  }
}