import 'package:flutter/material.dart' hide WidgetBuilder, MetaData;
import 'package:velix_di/di/di.dart';

import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/container.dart';
import '../widget_builder.dart';

@Injectable()
class ContainerEditWidgetBuilder extends WidgetBuilder<ContainerWidgetData> {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  ContainerEditWidgetBuilder({required this.typeRegistry})
      : super(name: "container", edit: true);

  // internal

  // override

  @override
  Widget create(ContainerWidgetData data) {
    return DragTarget<WidgetData>(
      onWillAccept: (event) => data.acceptsChild(event!),
      onAccept: (incoming) {
        // palette
        if (incoming is WidgetData && incoming.parent == null) {
          // link

          incoming.parent = data;

          data.children.add(incoming);
        }
        // reparent
        else {
          // reparenting drop
          // remove from old parent
          _removeFromParent(incoming);
          data.children.add(incoming);
        }
      },
      builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty;

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? Colors.blue : Colors.grey.shade400,
                width: isActive ? 3 : 1,
              ),
              color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.children
                  .map(
                    (child) => EditWidget(
                  model: child,
                  meta: typeRegistry[child.type],
                  parent: data,
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

    /*for (var top in canvasModels) {
      if (top == widget) {
        canvasModels.remove(top);
      } else if (top is ContainerWidgetData) {
        removeRecursive(top);
      }
      }*/
  }
}

@Injectable()
class ContainerWidgetBuilder extends WidgetBuilder<ContainerWidgetData> {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  ContainerWidgetBuilder({required this.typeRegistry})
      : super(name: "container");

  // lifecycle

  // override

  @override
  Widget create(ContainerWidgetData data) {
    return DragTarget<Object>(
      onWillAccept: (incoming) => true,
      onAccept: (incoming) {
        // palette
        if (incoming is String) {
          var metaData = typeRegistry[incoming];

          data.children.add(metaData.create());
        }
        // reparent
        else if (incoming is WidgetData) {
          // reparenting drop
          // remove from old parent
          _removeFromParent(incoming);
          data.children.add(incoming);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            color: Colors.grey.shade100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.children
                .map(
                  (child) => DynamicWidget(
                model: child,
                meta: typeRegistry[child.type],
                parent: data,
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

    /*for (var top in canvasModels) {
      if (top == widget) {
        canvasModels.remove(top);
      } else if (top is ContainerWidgetData) {
        removeRecursive(top);
      }
      }*/
  }
}