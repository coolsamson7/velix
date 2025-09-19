import 'dart:async';

import 'package:flutter/material.dart';

import '../event/events.dart';
import '../metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';
import '../util/message_bus.dart';

class WidgetTreeController extends ChangeNotifier {
  // instance data

  final List<WidgetData> roots;

  /// Tracks which nodes are expanded
  final Map<WidgetData, bool> _expanded = {};

  /// Currently selected node
  WidgetData? selectedNode;

  late final StreamSubscription<SelectionEvent> _busSub;
  final MessageBus bus;

  // constructor

  WidgetTreeController({required this.roots, required this.bus}) {
    _busSub = bus.subscribe<SelectionEvent>("selection", _onSelectionEvent);
  }

  // internal

  void _onSelectionEvent(SelectionEvent event) {
    if (selectedNode != event.selection) {
      selectedNode = event.selection;
      notifyListeners();
    }
  }

  // override

  @override
  void dispose() {
    _busSub.cancel();
    super.dispose();
  }

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

  /// Moves a node (drag & drop) while preventing cycles
  bool moveNode({required WidgetData source, WidgetData? target}) {
    WidgetData? p = target;
    while (p != null) {
      if (p == source) return false; // can't drop into own child
      p = p.parent;
    }

    // detach from old parent
    if (source.parent != null) {
      source.parent!.children.remove(source);
    }
    else {
      roots.remove(source);
    }

    // attach to new parent
    if (target == null) {
      roots.add(source);
      source.parent = null;
    }
    else {
      target.children.add(source);
      source.parent = target;
    }

    notifyListeners();
    return true;
  }
}

class WidgetTreeView extends StatefulWidget {
  // instance data

  final WidgetTreeController controller;

  // constructor

  const WidgetTreeView({super.key, required this.controller});

  // override

  @override
  State<WidgetTreeView> createState() => _WidgetTreeViewState();
}

class _WidgetTreeViewState extends State<WidgetTreeView> {
  // override

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant WidgetTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
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
          onWillAccept: (data) => data != null && data != node,
          onAccept: (data) =>
              widget.controller.moveNode(source: data, target: node),
          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              onTap: () => widget.controller.selectNode(node),
              child: Container(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : candidateData.isNotEmpty
                    ? Colors.green.withOpacity(0.2)
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(width: depth * 16),
                    if (hasChildren)
                      IconButton(
                        icon: Icon(
                            isExpanded ? Icons.expand_more : Icons.chevron_right),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            widget.controller.toggleExpanded(node),
                      )
                    else
                      const SizedBox(width: 24),
                    LongPressDraggable<WidgetData>(
                      data: node,
                      feedback: Material(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.grey.shade200,
                          child: Text(node.type),
                        ),
                      ),
                      child: Text(node.type),
                    ),
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

class WidgetTreePanel extends StatefulWidget {
  // instance data

  final List<WidgetData> models;

  // constructor

  const WidgetTreePanel({required this.models, super.key});

  @override
  State<WidgetTreePanel> createState() => _WidgetTreePanelState();
}

class _WidgetTreePanelState extends State<WidgetTreePanel> {
  // instance data

  late WidgetTreeController controller;
  late MessageBus bus;

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();
    controller = WidgetTreeController(roots: widget.models, bus: bus);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetTreeView(controller: controller);
  }
}