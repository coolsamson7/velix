import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:sample/editor/event/events.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../components/panel_header.dart';
import '../metadata/widget_data.dart';
import '../provider/environment_provider.dart';
import '../util/message_bus.dart';

class JsonEditorPanel extends StatefulWidget {
  const JsonEditorPanel({super.key});

  @override
  _JsonEditorPanelState createState() => _JsonEditorPanelState();
}

class _JsonEditorPanelState extends State<JsonEditorPanel> {
  // instance data

  WidgetData? root;

  late String jsonString = "";
  late final StreamSubscription _subscription;
  late final StreamSubscription _changeSubscription;

  // internal

  void updateJson(Map<String, dynamic> newJson) {
    setState(() {
      jsonString = const JsonEncoder.withIndent('  ').convert(newJson);
    });
  }

  void setWidget(WidgetData? root) {
    this.root = root;

    updateJson(JSON.serialize(root)); // initial JSON
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Acquire bus from environment and subscribe once

    final env = EnvironmentProvider.of(context);
    var bus = env.get<MessageBus>();

    _subscription = bus.subscribe<LoadEvent>("load", (event) {
      // update selected item (event.selection may be null)
      setWidget(event.widget);
    });
    _changeSubscription = bus.subscribe<PropertyChangeEvent>("property-changed", (event) {
      // update selected item (event.selection may be null)
      setWidget(root);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _changeSubscription.cancel();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade50,
      child: PanelContainer(
        title: "JSON",
        onClose: () => {},
        child: SingleChildScrollView(
          child: HighlightView(
            jsonString,
            language: 'json',
            theme: githubTheme,
            padding: const EdgeInsets.all(8),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
