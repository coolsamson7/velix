import 'package:flutter/cupertino.dart';

import '../commands/command.dart';
import './command_button.dart';

/// a toolbar containing [CommandButton]s
///
class CommandToolbar extends StatelessWidget {
  // instance data

  final List<CommandDescriptor> commands;

  // constructor

  /// create a new [CommandToolbar]
  /// [commands] list of commands
  const CommandToolbar({super.key,  required this.commands});

  // override

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: commands
          .map((command) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CommandButton(command: command))
          ).toList(),
    );
  }
}