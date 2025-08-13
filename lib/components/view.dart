import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../commands/command.dart';
import 'command_button.dart';
import 'overlay.dart';

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

class CommandView extends StatefulWidget {
  // instance data

  final Widget child;
  final List<CommandDescriptor> commands;

  // constructor

  const CommandView({
    super.key,
    required this.child,
    required this.commands,
  });

  // override

  @override
  State<CommandView> createState() => _CommandViewState();
}

class _CommandViewState extends State<CommandView> {
  bool _busy = false;

  bool _cursorBusy = false;

  void _setCursorBusy(bool busy) {
    setState(() {
      _cursorBusy = busy;
      print(busy);
    });
  }


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

  void _setBusy(bool busy) {
    setState(() {

      _busy = busy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildToolbar(),
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
      children: widget.commands
          .map((command) => CommandButton(command: command))
          .toList(growable: false),
    );
  }
}
