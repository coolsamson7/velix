import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

import '../components/panel_header.dart';

class JsonEditorPanel extends StatelessWidget {
  // constructor

  const JsonEditorPanel({super.key});

  // override

  @override
  Widget build(BuildContext context) {
    String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert({"foo": 1}); // TODO

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
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          )),
    );
  }

/*Map<String, dynamic> _serializeWidget(WidgetData widget) {
    Map<String, dynamic> map = {'type': widget.type};

    final meta = metadata[widget.type]!;

    for (var prop in meta.properties) {
      final value = TypeDescriptor.forType(widget.runtimeType).get(widget, prop.name);
      if (value is WidgetData) {
        map[prop.name] = _serializeWidget(value);
      } else if (value is List<WidgetData>) {
        map[prop.name] = value.map((w) => _serializeWidget(w)).toList();
      } else {
        map[prop.name] = value;
      }
    }

    return map;
  }*/
}