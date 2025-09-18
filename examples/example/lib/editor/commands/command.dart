import 'command_stack.dart';

/// Command interface
abstract class Command {
  // instance data

  CommandStack? stack;

  // abstract

  void execute();

  // Undo the command action (with stack cleanup)
  void undo() {
    // Remove this command and all previous commands from the stack
    stack?.removeUpToAndIncluding(this);
  }
}