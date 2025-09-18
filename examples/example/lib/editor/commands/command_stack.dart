import 'package:flutter/foundation.dart';
import 'package:sample/editor/commands/property_changed_command.dart';
import 'package:velix_di/di/di.dart';

import 'command.dart';

// Stack manager class
@Injectable(scope: "environment", eager: false)
class CommandStack extends ChangeNotifier {
  // instance data

  final List<Command> _stack = [];

  // public

  void revert(dynamic object, String property) {
    bool applies(Command command) {
      if ( command is PropertyChangeCommand) {
        if (identical(command.target, object) && command.property == property)
          return true;
      }

      return false;
    }

    // undo the first command

    _stack.firstWhere(applies).undo();

    // get rid of the rest

    for (var i = _stack.length - 1; i >= 0; i--)
      if ( applies(_stack[i])) {
        _stack.removeAt(i);
      }
  }

  bool propertyIsDirty(dynamic object, String property) {
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

  Command? tos() {
    return _stack.isNotEmpty ? _stack.last : null;
  }

  void undo() {
    if ( isDirty())
      tos()!.undo();
  }

  Command addCommand(Command cmd) {
    var wasDirty = isDirty();

    cmd.stack = this;

    _stack.add(cmd);
    cmd.execute();

    if ( wasDirty != isDirty())
      notifyListeners();

    return cmd;
  }

  void removeUpToAndIncluding(Command cmd) {
    var wasDirty = isDirty();

    int idx = _stack.indexOf(cmd);
    if (idx >= 0) {
      _stack.removeRange(0, idx + 1);

      if ( wasDirty != isDirty())
        notifyListeners();
    }
  }
}