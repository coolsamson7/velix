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

  // internal

  void selectMessage(Message message) {
    if (message.widget != null) {
      EnvironmentProvider.of(context)
          .get<MessageBus>().publish("selection", SelectionEvent(selection: message.widget, source: this));
    }
  }

  // override

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
  @override
  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) return const SizedBox.shrink();

    return PanelContainer(
      title: "editor:docks.errors.label".tr(),
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.grey.shade800,
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text("Widget", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Property", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text("Message", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isWarning = message.type == MessageType.warning;

                return InkWell(
                  onTap: () => selectMessage(message),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isWarning ? Colors.orange.shade700 : Colors.red.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Widget column
                        Expanded(
                          flex: 2,
                          child: Text(
                            message.widget?.type ?? "",
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),

                        // Property column
                        Expanded(
                          flex: 2,
                          child: Text(
                            message.property ?? "",
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),

                        // Message column
                        Expanded(
                          flex: 4,
                          child: Text(
                            message.message,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}