import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/commands/command_stack.dart';
import 'package:velix_editor/event/events.dart';
import 'package:velix_editor/util/message_bus.dart';

import '../../commands/reparent_command.dart';
import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/row.dart';
import '../widget_builder.dart';

@Injectable()
class RowEditWidgetBuilder extends WidgetBuilder<RowWidgetData> {
  final TypeRegistry typeRegistry;

  RowEditWidgetBuilder({required this.typeRegistry})
      : super(name: "row", edit: true);

  @override
  Widget create(RowWidgetData data, Environment environment, BuildContext context) {
    return DragTarget<WidgetData>(
      onWillAccept: (widget) => data.acceptsChild(widget!),
      onAccept: (widget) {
        environment.get<CommandStack>().execute(
          ReparentCommand(
            bus: environment.get<MessageBus>(),
            widget: widget,
            newParent: data,
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) =>
            environment.get<MessageBus>().publish(
              "selection",
              SelectionEvent(selection: widget, source: this),
            ));
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        final hasChildren = data.children.isNotEmpty;

        return Container(
          constraints: const BoxConstraints(
            minWidth: 100,
            minHeight: 60,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey.shade400,
              width: isActive ? 3 : 1,
              style: hasChildren ? BorderStyle.solid : BorderStyle.solid,
            ),
            color: isActive
                ? Colors.blue.shade50
                : (hasChildren ? Colors.transparent : Colors.grey.shade50),
          ),
          child: hasChildren
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < data.children.length; i++) ...[
                EditWidget(model: data.children[i]),
                // Add spacing between children except for the last one
                if (i < data.children.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          )
              : Center(
            child: Text(
              isActive ? 'Drop widgets here' : 'Empty Container',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.blue.shade600 : Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      },
    );
  }
}

@Injectable()
class RowWidgetBuilder extends WidgetBuilder<RowWidgetData> {
  final TypeRegistry typeRegistry;

  RowWidgetBuilder({required this.typeRegistry})
      : super(name: "row");

  @override
  Widget create(RowWidgetData data, Environment environment, BuildContext context) {
    return Row(
        children: data.children.map((child) => DynamicWidget(
          model: child,
          meta: typeRegistry[child.type],
          parent: data,
        )).toList(growable: false)
    );
  }
}