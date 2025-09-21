import 'command_stack.dart';

/// Command interface
abstract class Command {
  // instance data

  CommandStack? stack;
  Command? parent;
  List<Command> children = [];

  // constructor

  Command({this.parent}) {
    if ( parent != null)
      parent!.children.add(this);
  }

  // abstract

  void execute();

  // Undo the command action (with stack cleanup)
  void undo({bool deleteOnly = false}) {
    if ( !deleteOnly )
      // Remove this command and all previous commands from the stack
      stack?.removeUpToAndIncluding(this);

    // remove from parent

    if ( parent != null) {
      parent!.children.remove(this);

      if (parent!.children.isEmpty)
        parent!.undo();
    }
  }
}