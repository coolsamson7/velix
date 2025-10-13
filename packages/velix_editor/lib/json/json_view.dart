import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/idea.dart'; // ✅ dark theme
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../components/panel_header.dart';
import '../event/events.dart';
import '../metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';
import '../util/message_bus.dart';

class JsonEditorPanel extends StatefulWidget {
  // instance data

  final WidgetData model;
  final VoidCallback onClose;

  // constructor

  const JsonEditorPanel({required this.model, required this.onClose, super.key});

  // override

  @override
  State<JsonEditorPanel> createState() => _JsonEditorPanelState();
}

class _JsonEditorPanelState extends State<JsonEditorPanel> {
  // instance data

  WidgetData? root;
  late String jsonString = "";
  late final StreamSubscription? _subscription;
  late final StreamSubscription? _changeSubscription;

  WidgetData getRoot(WidgetData widget) {
    while (widget.parent != null) {
      widget = widget.parent!;
    }
    return widget;
  }

  void updateJson(Map<String, dynamic> newJson) {
    setState(() {
      jsonString = const JsonEncoder.withIndent('  ').convert(newJson);
    });
  }

  void setWidget(WidgetData? root) {
    this.root = root;
    if (root != null) {
      updateJson(JSON.serialize(root));
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final env = EnvironmentProvider.of(context);
    var bus = env.get<MessageBus>();

    _subscription = bus.subscribe<LoadEvent>("load", (event) {
      setState(() {
        root = null;
      });
    });
    _changeSubscription = bus.subscribe<PropertyChangeEvent>("property-changed",
            (event) {
          setWidget(getRoot(event.widget!));
        });

    setWidget(widget.model);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _changeSubscription?.cancel();

    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      //color: const Color(0xFF1E1E1E), // dark background
      child: PanelContainer(
        title: "editor:docks.json.label".tr(),
        onClose: widget.onClose,
        child: SizedBox.expand(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: HighlightView(
                  jsonString,
                  language: 'json',
                  theme: ideaTheme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
