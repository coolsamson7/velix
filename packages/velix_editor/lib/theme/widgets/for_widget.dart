import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/commands/command_stack.dart';
import 'package:velix_editor/event/events.dart';
import 'package:velix_editor/util/message_bus.dart';

import '../../actions/action_evaluator.dart';
import '../../actions/eval.dart';
import '../../commands/reparent_command.dart';
import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/for.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

extension ForWidgetDataExtensions on ForWidgetData {
  Iterable<(dynamic, Widget)> expand(BuildContext buildContext, TypeRegistry typeRegistry, Environment environment) {
    final widgetContext = WidgetContextScope.of(buildContext);
    final instance = widgetContext.instance;

    // Compile the binding once
    Call? compiledCall;
    if (context.isNotEmpty) {
      final type = TypeDescriptor.forType(instance.runtimeType);
      compiledCall =  ActionCompiler.instance.compile(context, context: type);
    }

    // Evaluate list at runtime

    List<dynamic> items = compiledCall?.eval(instance) ?? const [];

    if (children.isEmpty) return [];

    final templateChild = children[0];

    return items.map<(dynamic, Widget)>((item) {
      return (item, WidgetContextScope(
        contextValue: WidgetContext(instance: item),
        child: DynamicWidget(
          model: templateChild,
          meta: typeRegistry[templateChild.type],
        ),
      ));
    });
  }
}

@Injectable()
class ForEditWidgetBuilder extends WidgetBuilder<ForWidgetData> {
  final TypeRegistry typeRegistry;

  ForEditWidgetBuilder({required this.typeRegistry})
      : super(name: "for", edit: true);

  @override
  Widget create(ForWidgetData data, Environment environment, BuildContext context) {
    return ForEditWidget(
      data: data,
      environment: environment,
      typeRegistry: typeRegistry,
    );
  }
}

class ForEditWidget extends StatefulWidget {
  final ForWidgetData data;
  final Environment environment;
  final TypeRegistry typeRegistry;

  const ForEditWidget({
    required this.data,
    required this.environment,
    required this.typeRegistry,
    super.key,
  });

  @override
  State<ForEditWidget> createState() => _ForEditWidgetState();
}

class _ForEditWidgetState extends State<ForEditWidget> {
  bool _isActive = false;

  List<Widget> _buildChildren() {
    return widget.data.children.map((childData) {
      return EditWidget(model: childData);
    }).toList(growable: false);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.data.children.isNotEmpty;

    return DragTarget<WidgetData>(
      onWillAccept: (widgetData) {
        final accept = widget.data.acceptsChild(widgetData!);
        setState(() => _isActive = accept);
        return accept;
      },
      onAccept: (widgetData) {
        widget.environment.get<CommandStack>().execute(
          ReparentCommand(
            bus: widget.environment.get<MessageBus>(),
            widget: widgetData,
            newParent: widget.data,
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.environment.get<MessageBus>().publish(
            "selection",
            SelectionEvent(selection: widgetData, source: widget),
          );
        });

        setState(() => _isActive = false);
      },
      onLeave: (_) => setState(() => _isActive = false),
      builder: (context, candidateData, rejectedData) {
        return Container(
          constraints: const BoxConstraints(minWidth: 100, minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isActive ? Colors.blue : Colors.grey.shade400,
              width: _isActive ? 3 : 1,
            ),
            color: _isActive
                ? Colors.blue.shade50
                : (hasChildren ? Colors.transparent : Colors.grey.shade50),
          ),
          child: hasChildren
              ? Row(
            children: [
              // Icon on the left with tooltip
              Tooltip(
                message: 'Binding: ${widget.data.context}',
                child: const Icon(Icons.loop, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              // Render children
              for (int i = 0; i < _buildChildren().length; i++) ...[
                _buildChildren()[i],
                if (i < _buildChildren().length - 1) const SizedBox(width: 8),
              ],
            ],
          )
              : Center(
            child: Text(
              _isActive ? 'Drop widgets here' : 'Empty Container',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isActive ? Colors.blue.shade600 : Colors.grey.shade600,
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
class ForWidgetBuilder extends  WidgetBuilder<ForWidgetData> {
  final TypeRegistry typeRegistry;

  ForWidgetBuilder({required this.typeRegistry})
      : super(name: "for");

  @override
  Widget create(ForWidgetData data, Environment environment, BuildContext context) {
    throw Exception("a for widget should not be created");
  }
}