import 'package:flutter/material.dart';

import '../edit_widget.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';

class EditorCanvas extends StatefulWidget {
  // static

  static WidgetData linkParents(WidgetData data) {
    void link(WidgetData data, WidgetData? parent) {
      data.parent = parent;
      for (var child in data.children)
        link(child, data);
    }

    link(data, null);

    // done

    return data;
  }

  // instance data

  final List<WidgetData> models;
  final TypeRegistry typeRegistry;

  // constructor

   EditorCanvas({super.key, required this.models, required this.typeRegistry}) {
    for ( var model in models)
      linkParents(model);
  }

  // override

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  // instance data

  TypeRegistry? typeRegistry;

  // override

  @override
  Widget build(BuildContext context) {
    typeRegistry ??= EnvironmentProvider.of(context).get<TypeRegistry>();

    return DragTarget<WidgetData>(
      onWillAccept: (_) => widget.models.isEmpty,
      onAccept: (w) {
        // palette

        widget.models.add(w);
        setState(() {});
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: Colors.grey.shade200,
          child: ListView(
            children: widget.models
                .map((m) => Padding(
                      padding: const EdgeInsets.all(8.0), // TODO?
                      child: EditWidget(model: m),
                    ),
            )
                .toList(),
          ),
        );
      },
    );
  }
}