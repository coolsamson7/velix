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
      if (event.type == MessageEventType.add) {
        _messages.addAll(event.messages);
      }
    });
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

    return PanelContainer(
      title: "editor:docks.errors.label".tr(),
      onClose: widget.onClose,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount: _messages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isWarning = message.type == MessageType.warning;

          return InkWell(
            onTap: () {if (message.onClick != null) message.onClick!();},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isWarning ? Colors.orange.shade700 : Colors.red.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}