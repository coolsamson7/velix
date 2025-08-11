import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';

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

  CommandDescriptor({required this.name, required this.function, this.i18n, this.label, this.icon}) {
    if ( i18n != null) {
      label = i18n; //TODO !.tr();
    }
    else if ( label == null) {
      label ??= name;
    }
  }

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

class Invocation {
  final CommandDescriptor command;
  List<dynamic> args;

  Invocation({required this.command, required this.args});
}

abstract class CommandInterceptor {
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next);
}

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

class MethodCommandInterceptor implements CommandInterceptor {
  @override
  Future<dynamic> call(Invocation invocation, FutureOr<dynamic> Function()? next) {
    return Future.value(Function.apply(invocation.command.function, invocation.args));
  }
}

@injectable
class CommandManager {
  // instance data

  MethodCommandInterceptor methodInterceptor = MethodCommandInterceptor();
  List<CommandInterceptor> interceptors = [];


  // constructor

  CommandManager({this.interceptors = const []});

  // public

  CommandDescriptor createCommand(String name, Function function, {String? i18n, String? label, IconData? icon}) {
    CommandDescriptor command = CommandDescriptor(name: name, function: function, i18n: i18n, label: label, icon: icon);

    for ( CommandInterceptor interceptor in interceptors)
      command.addInterceptor(interceptor);

    command.addInterceptor(methodInterceptor);

    return command;
  }
}


mixin CommandController {
  // instance data

  final Map<String, CommandDescriptor> _commands = {};
  late CommandManager commandManager;

  // public

  void setCommandManager(CommandManager commandManager) {
    this.commandManager = commandManager;
  }

  List<CommandDescriptor> getCommands() {
    return _commands.values.toList();
  }
  
  void addCommand(String name, Function function, {String? label, String? i18n, IconData? icon}) {
    // TODO _commands[name] = getIt<CommandManager>().createCommand(name, function, i18n: i18n, label: label, icon: icon);
  }

  CommandDescriptor getCommand(String name) {
    CommandDescriptor? command = _commands[name];
    if (command != null) {
      return command;
    }
    else {
      throw CommandException("unknown command '$name'");
    }
  }

  void setCommandEnabled(String command, bool enabled) {
    print("$command.enabled = $enabled");
    getCommand(command).enabled = enabled;
  }

  Future<dynamic> execute(String name, List<dynamic> args) {
    return getCommand(name).execute(args);
  }
}