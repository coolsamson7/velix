import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../commands/command.dart';

/// A button that is attached to a command
class CommandButton extends StatefulWidget {
  // instance data

  final CommandDescriptor command;
  late final String? label;
  late final IconData? icon;
  final List<dynamic>? args;
  final bool iconOnly;

  // constructor

  CommandButton({
    super.key,
    required this.command,
    String? label,
    IconData? icon,
    this.args,
    this.iconOnly=true
  }) {
    this.label = label ?? command.label;
    this.icon = icon ?? command.icon;
  }

  @override
  State<CommandButton> createState() => _CommandButtonState();
}

/// @internal
class _CommandButtonState extends State<CommandButton> {
  // instance data

  late VoidCallback listener;

  // override

  @override
  void initState() {
    super.initState();

    listener = () => setState(() {}); // just rerender
    widget.command.addListener(listener);
  }

  @override
  void didUpdateWidget(covariant CommandButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.command != widget.command) {
      oldWidget.command.removeListener(listener);
      widget.command.addListener(listener);
    }
  }

  @override
  void dispose() {
    widget.command.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.command.enabled;

    String label = widget.label ?? widget.command.label!;
    IconData? icon = widget.icon ?? widget.command.icon;

    if (widget.iconOnly) {
      // Icon only button with no background like iOS style
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: isEnabled ? () => widget.command.execute(widget.args ?? []) : null,
        child: Icon(
          icon,
          color: isEnabled ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
        ),
      );
    }

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: ElevatedButton(
          onPressed: () => widget.command.execute(widget.args ?? []),
          style: ElevatedButton.styleFrom(
            padding: widget.iconOnly ? const EdgeInsets.all(8) : null,
            minimumSize: widget.iconOnly ? const Size(40, 40) : null,
          ),
          child: widget.iconOnly
              ? (icon != null
              ? Icon(icon)
              : const SizedBox.shrink())
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}