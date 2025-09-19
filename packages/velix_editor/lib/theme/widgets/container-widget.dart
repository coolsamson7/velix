import 'package:flutter/material.dart' hide WidgetBuilder, MetaData;
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/commands/command_stack.dart';
import 'package:velix_editor/util/message_bus.dart';

import '../../commands/reparent_command.dart';
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
  Widget create(ContainerWidgetData data, Environment environment) {
    return DragTarget<WidgetData>(
      onWillAccept: (widget) => data.acceptsChild(widget!),
      onAccept: (widget) {
        environment.get<CommandStack>().addCommand(ReparentCommand(bus: environment.get<MessageBus>(), widget: widget, oldParent: widget.parent, newParent: data));
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
  Widget create(ContainerWidgetData data, Environment environment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.children
            .map((child) => DynamicWidget(
                    model: child,
                    meta: typeRegistry[child.type],
                    parent: data,
                  ),
        ).toList(),
      ),
    );
  }
}