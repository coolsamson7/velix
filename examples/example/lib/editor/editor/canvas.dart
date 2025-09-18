import 'package:flutter/material.dart' hide MetaData;

import '../dynamic_widget.dart';
import '../metadata/metadata.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import '../metadata/widgets/container.dart';
import '../provider/environment_provider.dart';

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
  final Map<String, MetaData> metadata;

  // constructor

   EditorCanvas({super.key, required this.models, required this.metadata}) {
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

    return DragTarget<Object>(
      onWillAccept: (_) => true,
      onAccept: (incoming) {
        // palette

        if (incoming is String) {
          WidgetData newWidget = typeRegistry![incoming].create();

          setState(() => widget.models.add(newWidget));
        }
        // reparenting
        else if (incoming is WidgetData) {
          _removeFromParent(incoming);

          setState(() => widget.models.add(incoming));
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: Colors.grey.shade200,
          child: ListView(
            children: widget.models
                .map(
                  (m) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: DynamicWidget(
                  model: m,
                  meta: widget.metadata[m.type]!,
                ),
              ),
            )
                .toList(),
          ),
        );
      },
    );
  }

  void _removeFromParent(WidgetData widget) {
    void removeRecursive(WidgetData container) {
      container.children.remove(widget);
      for (var child in container.children) {
        removeRecursive(child);
      }
    }

    /*for (var top in widget.models) {
      if (top == widget) {
        widget.models.remove(top);
      } else if (top is ContainerWidgetData) {
        removeRecursive(top);
      }
    }*/
  }
}