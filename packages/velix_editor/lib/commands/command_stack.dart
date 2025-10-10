import 'package:flutter/foundation.dart';
import 'package:velix/util/tracer.dart';

import 'package:velix_di/di/di.dart';

import 'command.dart';
import 'property_changed_command.dart';

// Stack manager class

@Injectable(scope: "environment", eager: false)
class CommandStack extends ChangeNotifier {
  // instance data

  final List<Command> _stack = [];

  // public

  void revert(dynamic object, String property) {
    // local function

    bool applies(Command command) {
      if ( command is PropertyChangeCommand) {
        if (identical(command.target, object) && command.property == property)
          return true;
      }

      return false;
    }

    var wasDirty = isDirty();

    // undo the first command

    _stack.firstWhere(applies).undo(deleteOnly: true);

    // get rid of the rest

    for (var i = _stack.length - 1; i >= 0; i--)
      if ( applies(_stack[i])) {
        _stack.removeAt(i);
      }

    // did we change out state?

    _changeDirty(wasDirty);
  }

  void _changeDirty(bool wasDirty) {
    if ( wasDirty != isDirty()) {
      if (Tracer.enabled)
        Tracer.trace("editor.history", TraceLevel.high, "history.dirty = ${isDirty()}");

      notifyListeners();
    }
  }

  bool propertyIsDirty(dynamic object, String property) {
    // local function

    bool applies(Command command) {
      if ( command is PropertyChangeCommand) {
        if (identical(command.target, object) && command.property == property)
          return true;
      }

      return false;
    }

    for (var command in _stack)
      if ( applies(command))
        return true;

    return false;
  }

  bool isDirty() {
    return _stack.isNotEmpty;
  }

  void clear() {
    _stack.clear();
  }

  Command? tos() {
    return _stack.isNotEmpty ? _stack.last : null;
  }

  void undo({bool silent = false}) {
    if ( isDirty())
      tos()!.undo(silent: silent);
  }

  Command execute(Command cmd) {
    if ( Tracer.enabled)
      Tracer.trace("editor.history", TraceLevel.high, "add command");

    var wasDirty = isDirty();

    cmd.stack = this;

    _stack.add(cmd);
    cmd.execute();

    _changeDirty(wasDirty);

    return cmd;
  }

  void removeUpToAndIncluding(Command cmd) {
    var wasDirty = isDirty();

    int idx = _stack.indexOf(cmd);
    if (idx >= 0) {
      _stack.removeRange(0, idx + 1);

      _changeDirty(wasDirty);
    }
  }
}