import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../commands/reparent_command.dart';
import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../event/events.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/dropdown.dart';
import '../../metadata/widgets/for.dart';

import '../../util/message_bus.dart';
import '../widget_builder.dart';
import 'for_widget.dart';

@Injectable()
class DropDownWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  final TypeRegistry typeRegistry;

  DropDownWidgetBuilder({required this.typeRegistry}) : super(name: "dropdown");

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    return _DropDownWidget(
      data: data,
      typeRegistry: typeRegistry,
      environment: environment,
    );
  }
}

class _DropDownWidget extends StatefulWidget {
  final DropDownWidgetData data;
  final TypeRegistry typeRegistry;
  final Environment environment;

  const _DropDownWidget({
    required this.data,
    required this.typeRegistry,
    required this.environment,
  });

  @override
  State<_DropDownWidget> createState() => _DropDownWidgetState();
}

class _DropDownWidgetState extends State<_DropDownWidget> {
  dynamic _selectedValue;

  List<DropdownMenuItem<dynamic>> _buildItems(BuildContext context) {
    final items = <DropdownMenuItem<dynamic>>[];

    List<Widget> children = [];

    for (var childData in widget.data.children) {
      if (childData is ForWidgetData) {
        for (var (instance, item) in childData.expand(context, widget.typeRegistry, widget.environment)) {
          items.add(DropdownMenuItem(
            value: instance,
            child: item,
          ));
        }
      } else {
        // Static widget
        items.add(DropdownMenuItem(
          value: childData,
          child: DynamicWidget(
            model: childData,
            meta: widget.typeRegistry[childData.type],
          ),
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<dynamic>(
      value: _selectedValue,
      hint: const Text('Select'),
      items: _buildItems(context),
      onChanged: (value) {
        setState(() {
          _selectedValue = value;
        });

        widget.environment.get<MessageBus>().publish(
          "selection",
          SelectionEvent(selection: value, source: this),
        );
      },
    );
  }
}



@Injectable()
class DropDownEditWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  final TypeRegistry typeRegistry;

  DropDownEditWidgetBuilder({required this.typeRegistry})
      : super(name: "dropdown", edit: true);

  @override
  Widget create(
      DropDownWidgetData data, Environment environment, BuildContext context) {
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

        final fakeSelectedChild =
        hasChildren ? EditWidget(model: data.children.first) : null;

        return Container(
          constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey.shade400,
              width: isActive ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isActive
                ? Colors.blue.shade50
                : Colors.grey.shade100.withOpacity(0.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: fakeSelectedChild ??
                    Text(
                      isActive ? 'Drop option here' : 'Select an item',
                      style: TextStyle(
                        color: isActive
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        fontStyle: hasChildren
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}

