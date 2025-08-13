import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:velix/i18n/i18n.dart';

/// @internal
class Command {
  final String? name;
  final String? i18n;
  final String? label;
  //IconData? icon;

  const Command({this.name, this.label, this.i18n});
}

class CommandException implements Exception {
  final String message;

  CommandException(this.message);

  @override
  String toString() => 'CommandException: $message';
}

/// @internal
class CommandDescriptor extends ChangeNotifier {
  // instance data

  final String name;
  final String? i18n;
  late String? label;
  late IconData? icon;
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

  CommandDescriptor({required this.name, required this.function, this.i18n, this.label, this.icon});

  // administrative

  void addInterceptor(CommandInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  void prependInterceptor(CommandInterceptor interceptor) {
    _interceptors.insert(0, interceptor);
  }

  // public

  Future<dynamic> execute(List<dynamic> args) {
    Invocation invocation = Invocation(command: this, args: args);

    // local function

    FutureOr<dynamic> callNext(int index) {
      return _interceptors[index](invocation, () => callNext(index + 1));
    }

    return Future.sync(() => callNext(0));
  }
}

/// Covers the parameters of a command invocation:
/// - the command name
/// - the args
class Invocation {
  final CommandDescriptor command;
  List<dynamic> args;

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
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next) {
    print("> ${invocation.command.name}");
    try {
      return Future.value(next!());
    }
    finally {
      print("< ${invocation.command.name}");
    }
  }
}

/// A [CommandInterceptor] that disables a command while being executed.
class LockCommandInterceptor implements CommandInterceptor {
  @override
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next) {
    bool enabled = invocation.command.enabled;
    try {
      invocation.command.enabled = false;

      return Future.value(next!());
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
  Translator translator;

  // constructor

  CommandManager({this.interceptors = const [], this.translator = NO_TRANSLATOR});

  // public

  CommandDescriptor createCommand(String name, Function function, {String? i18n, String? label, IconData? icon}) {
    if ( label != null) {
      if (i18n != null) {
        label = translator.translate(i18n);
      }
      else {
        label = name;
      }
    }

    CommandDescriptor command = CommandDescriptor(name: name, function: function, i18n: i18n, label: label, icon: icon);

    // add standard interceptors

    for ( CommandInterceptor interceptor in interceptors)
      command.addInterceptor(interceptor);

    // the method itself

    command.addInterceptor(methodInterceptor);

    return command;
  }
}

/// Mixin class that adds the ability to handle commands
mixin CommandController<T extends StatefulWidget> on State<T> {
  // instance data

  final Map<String, CommandDescriptor> _commands = {};
  late CommandManager commandManager;

  // public

  /// @internal
  List<CommandDescriptor> getCommands() {
    return _commands.values.toList();
  }

  /// @internal
  void addCommand(String name, Function function, {String? label, String? i18n, IconData? icon}) {
    _commands[name] = commandManager.createCommand(name, function, i18n: i18n, label: label, icon: icon);
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