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
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/for.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

List<Widget> expandForWidget(
    BuildContext context,
    ForWidgetData data,
    TypeRegistry typeRegistry,
    Environment environment,
    ) {
  final widgetContext = WidgetContextScope.of(context);
  final instance = widgetContext.instance;

  // Compile the binding once
  Call? compiledCall;
  if (data.context != null) {
    final type = TypeDescriptor.forType(instance.runtimeType);
    compiledCall = ActionCompiler.instance.compile(data.context!, context: type);
  }

  // Evaluate list at runtime
  final items = compiledCall?.eval(instance) ?? const [];

  if (data.children.isEmpty) return [];

  final templateChild = data.children[0];

  return items.map((item) {
    return WidgetContextScope(
      contextValue: WidgetContext(instance: item),
      child: DynamicWidget(
        model: templateChild,
        meta: typeRegistry[templateChild.type],
      ),
    );
  }).toList(growable: false);
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
      if (childData is ForWidgetData) {
        return ForWidget(
          data: childData,
          environment: widget.environment,
          typeRegistry: widget.typeRegistry,
        );
      } else {
        return DynamicWidget(
          model: childData,
          meta: widget.typeRegistry[childData.type],
        );
      }
    }).toList(growable: false);
  }

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
    return ForWidget(data: data, environment: environment, typeRegistry: typeRegistry);
  }
}

class WidgetList extends StatefulWidget {
  final List<WidgetData> children;
  final Environment environment;
  final TypeRegistry typeRegistry;

  const WidgetList({
    required this.children,
    required this.environment,
    required this.typeRegistry,
    super.key,
  });

  @override
  State<WidgetList> createState() => _WidgetListState();
}

class _WidgetListState extends State<WidgetList> {
  List<Widget> _buildChildren(BuildContext context) {
    List<Widget> result = [];

    for (var childData in widget.children) {
      if (childData is ForWidgetData) {
        /* Expand ForWidget dynamically
        result.add(ForWidget(
          data: childData,
          environment: widget.environment,
          typeRegistry: widget.typeRegistry,
        ));*/

        result.addAll(expandForWidget( context,
          childData,
          widget.typeRegistry,
          widget.environment));
      } else {
        // Static widgets
        result.add(DynamicWidget(
          model: childData,
          meta: widget.typeRegistry[childData.type],
        ));
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildChildren(context),
    );
  }
}

class ForWidget extends StatefulWidget {
  final ForWidgetData data;
  final Environment environment;
  final TypeRegistry typeRegistry;

  const ForWidget({
    required this.data,
    required this.environment,
    required this.typeRegistry,
    super.key,
  });

  /// Evaluate the list and produce widgets at runtime
  List<Widget> buildList(
      BuildContext context,
      ) {
    final widgetContext = WidgetContextScope.of(context);
    final instance = widgetContext.instance;

    Call? compiledCall;
    if (data.context != null) {
      final type = TypeDescriptor.forType(instance.runtimeType);
      compiledCall = ActionCompiler.instance.compile(data.context!, context: type);
    }

    List<dynamic> items = compiledCall?.eval(instance) ?? const [];

    if (data.children.isEmpty) return [];

    final templateChild = data.children[0];

    List<Widget> r = items.map((item) =>
       WidgetContextScope(
        contextValue: WidgetContext(instance: item),
        child: DynamicWidget(
          model: templateChild,
          meta: typeRegistry[templateChild.type],
        ),
      )).toList(growable: false);

    return r;
  }

  @override
  State<ForWidget> createState() => _ForWidgetState();
}

class _ForWidgetState extends State<ForWidget> {
  @override
  Widget build(BuildContext context) {
    // By default, render a Column of children
    final children = widget.buildList(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
