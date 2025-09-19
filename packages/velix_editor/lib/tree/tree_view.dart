import 'dart:async';
import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../commands/command_stack.dart';
import '../commands/reparent_command.dart';
import '../event/events.dart';
import '../metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';
import '../util/message_bus.dart';

/// Controller to handle tree state, selection, expansion, and drag/drop
class WidgetTreeController extends ChangeNotifier {
  final List<WidgetData> roots;

  /// Tracks expanded state per node
  final Map<WidgetData, bool> _expanded = {};

  WidgetData? selectedNode;

  late final StreamSubscription<SelectionEvent> _selectionSub;
  late final StreamSubscription<PropertyChangeEvent> _propertySub;

  final MessageBus bus;

  WidgetTreeController({required this.roots, required this.bus}) {
    _selectionSub = bus.subscribe<SelectionEvent>("selection", _onSelection);
    _propertySub =
        bus.subscribe<PropertyChangeEvent>("property-changed", _onPropertyChanged);
  }

  // --------------------
  // Bus event handlers
  // --------------------

  void _onSelection(SelectionEvent event) {
    if (selectedNode != event.selection) {
      selectedNode = event.selection;
      notifyListeners();
    }
  }

  void _onPropertyChanged(PropertyChangeEvent event) {
    if (_isNodeInTree(event.widget!)) {
      notifyListeners();
    }
  }

  bool _isNodeInTree(WidgetData node) {
    bool contains(List<WidgetData> nodes) {
      for (var n in nodes) {
        if (identical(n, node)) return true;
        if (contains(n.children)) return true;
      }
      return false;
    }

    return contains(roots);
  }

  // --------------------
  // Public API
  // --------------------

  bool isExpanded(WidgetData node) => _expanded[node] ?? true;

  void toggleExpanded(WidgetData node) {
    _expanded[node] = !(isExpanded(node));
    notifyListeners();
  }

  void selectNode(WidgetData node) {
    if (selectedNode != node) {
      selectedNode = node;
      bus.publish("selection", SelectionEvent(selection: node, source: this));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _selectionSub.cancel();
    _propertySub.cancel();
    super.dispose();
  }
}

/// WidgetTree view
class WidgetTreeView extends StatefulWidget {
  final WidgetTreeController controller;

  const WidgetTreeView({super.key, required this.controller});

  @override
  State<WidgetTreeView> createState() => _WidgetTreeViewState();
}

class _WidgetTreeViewState extends State<WidgetTreeView> {
   late final Environment environment;

  // override

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = Environment(parent: EnvironmentProvider.of(context));
  }

  void _onControllerUpdate() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children:
      widget.controller.roots.map((node) => _buildNode(node, 0)).toList(),
    );
  }

  Widget _buildNode(WidgetData node, int depth) {
    final isExpanded = widget.controller.isExpanded(node);
    final isSelected = widget.controller.selectedNode == node;
    final hasChildren = node.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<WidgetData>(
          onWillAccept: (widget) => node.acceptsChild(widget!),
          onAccept: (widget) => environment.get<CommandStack>().execute(ReparentCommand(bus: environment.get<MessageBus>(), widget: widget, newParent: node)),
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;

            return GestureDetector(
              onTap: () => widget.controller.selectNode(node),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : null,
                  border: isHovering
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                ),
                padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(width: depth * 16),
                    if (hasChildren)
                      IconButton(
                        icon: Icon(isExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            widget.controller.toggleExpanded(node),
                      )
                    else
                      const SizedBox(width: 24),
                    Expanded(child: Draggable<WidgetData>(
                      data: node,
                      feedback: Material(
                        elevation: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey.shade200,
                          child: Text(node.type),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: Text(node.type),
                      ),
                      child: Text(node.type),
                    )),
                  ],
                ),
              ),
            );
          },
        ),
        if (hasChildren && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
              node.children.map((c) => _buildNode(c, depth + 1)).toList(),
            ),
          ),
      ],
    );
  }
}

/// Top-level panel for the tree
class WidgetTreePanel extends StatefulWidget {
  final List<WidgetData> models;

  const WidgetTreePanel({required this.models, super.key});

  @override
  State<WidgetTreePanel> createState() => _WidgetTreePanelState();
}

class _WidgetTreePanelState extends State<WidgetTreePanel> {
  late WidgetTreeController controller;
  late MessageBus bus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();
    controller = WidgetTreeController(roots: widget.models, bus: bus);
  }

  @override
  Widget build(BuildContext context) {
    return WidgetTreeView(controller: controller);
  }
}
