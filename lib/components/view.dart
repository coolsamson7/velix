import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../commands/command.dart';
import 'command_button.dart';
import 'overlay.dart';

/// @internal [CommandInterceptor] that is used to change the cursor after n ms
class _CursorInterceptor implements CommandInterceptor {
  final void Function(bool) onChange;
  final Duration delay;
  Timer? _timer;
  bool _shown = false;

  _CursorInterceptor({
    required this.onChange,
    this.delay = const Duration(milliseconds: 300),
  });

  @override
  Future<dynamic> call(Invocation invocation, FutureOr Function()? next) async {
    // Start delayed cursor change
    _timer = Timer(delay, () {
      _shown = true;
      onChange(true); // show busy cursor
    });

    try {
      final result = await next!();
      return result;
    }
    finally {
      _timer?.cancel();
      if (_shown) onChange(false); // restore cursor
    }
  }
}

/// @internal [CommandInterceptor] that is used to show a spinner overlay while executing a command
class _SpinnerInterceptor implements CommandInterceptor {
  final void Function(bool) onChange;

  _SpinnerInterceptor({required this.onChange});

  @override
  Future<dynamic> call(Invocation invocation, FutureOr Function()? next) async {
    onChange(true);
    try {
      return await next!();
    }
    finally {
      onChange(false);
    }
  }
}

const List<CommandDescriptor> noCommands = [];

/// a widget that is associated with commands and will change the cursor or show a spinner while executing commands.
class CommandView extends StatefulWidget {
  // instance data

  final Widget child;
  final List<CommandDescriptor> commands;
  final List<CommandDescriptor> toolbarCommands;

  // constructor

  /// Create a new [CommandView]
  /// [commands] list of commands
  const CommandView({
    super.key,
    required this.child,
    required this.commands,
    this.toolbarCommands = noCommands,
  });

  // override

  @override
  State<CommandView> createState() => _CommandViewState();
}

/// @internal
class _CommandViewState extends State<CommandView> {
  // instance data

  bool _busy = false;
  bool _cursorBusy = false;

  // internal

  void _setCursorBusy(bool busy) {
    setState(() {
      _cursorBusy = busy;
      print(busy);
    });
  }

  void _setBusy(bool busy) {
    setState(() {

      _busy = busy;
    });
  }

  // override

  @override
  void initState() {
    super.initState();

    // Add spinner interceptor to each command

    for (var command in widget.commands) {
      if (command.lock == LockType.view)
        command.prependInterceptor(_SpinnerInterceptor(onChange: _setBusy));
      else
        command.prependInterceptor(
            _CursorInterceptor(
              onChange: _setCursorBusy,
              delay: const Duration(milliseconds: 300),
            ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            if ( widget.toolbarCommands.isNotEmpty ) _buildToolbar(),
            Expanded(
              child: OverlaySpinner(
                show: _busy,
                child: widget.child,
              ),
            ),
          ],
        ),

        // Cursor overlay
        if (_cursorBusy)
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.progress,
              child: const SizedBox.expand(), // transparent hitbox
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: widget.toolbarCommands
          .map((command) => CommandButton(command: command))
          .toList(growable: false),
    );
  }
}
