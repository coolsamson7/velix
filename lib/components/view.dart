import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../commands/command.dart';
import 'command_button.dart';
import 'overlay.dart';

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

  @override
  void initState() {
    super.initState();

    // Add spinner interceptor to each command
    for (var cmd in widget.commands) {
      cmd.prependInterceptor(_SpinnerInterceptor(onChange: _setBusy));
    }
  }

  void _setBusy(bool busy) {
    setState(() {
      _busy = busy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: OverlaySpinner(
            show: _busy,
            child: widget.child,
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
