import 'dart:async';
import 'package:flutter/material.dart';
import 'package:velix_editor/event/events.dart';
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_ui/provider/environment_provider.dart';

import '../components/panel_header.dart';
import '../util/message_bus.dart';

class MessagePane extends StatefulWidget {
  final VoidCallback onClose;

  const MessagePane({super.key, required this.onClose});

  @override
  State<MessagePane> createState() => _MessagePaneState();
}

class _MessagePaneState extends State<MessagePane> {
  final List<Message> _messages = [];
  late StreamSubscription<MessageEvent> subscription;

  void _onMessageEvent(MessageEvent event) {
    setState(() {
      switch (event.type) {
        case MessageEventType.add:
          _messages.addAll(event.messages);
          break;
        case MessageEventType.set:
          _messages.clear();
          _messages.addAll(event.messages);
          break;
        case MessageEventType.clear:
          _messages.clear();
          break;
      }
    });
  }

  void selectMessage(Message message) {
    if (message.widget != null) {
      EnvironmentProvider.of(context)
          .get<MessageBus>()
          .publish("selection", SelectionEvent(selection: message.widget, source: this));
    }
  }

  Color _getMessageColor(MessageType type) {
    switch (type) {
      case MessageType.error:
        return Colors.red.shade600;
      case MessageType.warning:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    subscription = EnvironmentProvider.of(context)
        .get<MessageBus>()
        .subscribe<MessageEvent>("messages", _onMessageEvent);
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return PanelContainer(
      title: "editor:docks.errors.label".tr(),
      onClose: widget.onClose,
      child: ListView.builder(
        padding: EdgeInsets.zero, // remove outer space
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final messageColor = _getMessageColor(message.type);

          final bool isEven = index % 2 == 0;
          final Color backgroundColor = isEven
              ? theme.colorScheme.surfaceVariant.withOpacity(0.05)
              : theme.colorScheme.surfaceVariant.withOpacity(0.1);

          return _MessageRow(
            message: message,
            backgroundColor: backgroundColor,
            hoverColor: theme.colorScheme.primary.withOpacity(0.1),
            iconColor: messageColor,
            onTap: () => selectMessage(message),
          );
        },
      ),
    );
  }
}

class _MessageRow extends StatefulWidget {
  final Message message;
  final Color backgroundColor;
  final Color hoverColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _MessageRow({
    required this.message,
    required this.backgroundColor,
    required this.hoverColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  State<_MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends State<_MessageRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          color: _hovered ? widget.hoverColor : widget.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.message.type == MessageType.error
                  ? Icons.error
                  : widget.message.type == MessageType.warning
                  ? Icons.warning
                  : Icons.info_outline,
                  color: widget.iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  widget.message.widget?.type ?? "-",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  widget.message.property ?? "-",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Text(
                  widget.message.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
