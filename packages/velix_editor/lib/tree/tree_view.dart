import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/type_registry.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../commands/command_stack.dart';
import '../commands/reparent_command.dart';
import '../components/panel_header.dart';
import '../event/events.dart';
import '../metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';
import '../util/message_bus.dart';

/// Controller to handle tree state, selection, expansion, and drag/drop
class WidgetTreeController extends ChangeNotifier {
  List<WidgetData> roots;

  /// Tracks expanded state per node
  final Map<WidgetData, bool> _expanded = {};

  WidgetData? selectedNode;

  late final StreamSubscription<SelectionEvent> _selectionSub;
  late final StreamSubscription<LoadEvent> _loadSub;
  late final StreamSubscription<PropertyChangeEvent> _propertySub;

  final MessageBus bus;

  WidgetTreeController({required this.roots, required this.bus}) {
    _selectionSub = bus.subscribe<SelectionEvent>("selection", _onSelection);
    _loadSub = bus.subscribe<LoadEvent>("load", _onLoad);

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

  void _onLoad(LoadEvent event) {
    selectedNode = null;
    roots = [event.widget!];

    notifyListeners();
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
  // Keyboard Navigation
  // --------------------

  List<WidgetData> _getFlattenedNodes() {
    List<WidgetData> flattened = [];

    void addNodesRecursively(List<WidgetData> nodes, int depth) {
      for (var node in nodes) {
        flattened.add(node);
        if (isExpanded(node) && node.children.isNotEmpty) {
          addNodesRecursively(node.children, depth + 1);
        }
      }
    }

    addNodesRecursively(roots, 0);
    return flattened;
  }

  void navigateUp() {
    if (selectedNode == null) {
      if (roots.isNotEmpty) selectNode(roots.first);
      return;
    }

    final flattened = _getFlattenedNodes();
    final currentIndex = flattened.indexOf(selectedNode!);
    if (currentIndex > 0) {
      selectNode(flattened[currentIndex - 1]);
    }
  }

  void navigateDown() {
    if (selectedNode == null) {
      if (roots.isNotEmpty) selectNode(roots.first);
      return;
    }

    final flattened = _getFlattenedNodes();
    final currentIndex = flattened.indexOf(selectedNode!);
    if (currentIndex >= 0 && currentIndex < flattened.length - 1) {
      selectNode(flattened[currentIndex + 1]);
    }
  }

  void expandOrMoveRight() {
    if (selectedNode == null) return;

    if (selectedNode!.children.isNotEmpty) {
      if (!isExpanded(selectedNode!)) {
        toggleExpanded(selectedNode!);
      } else {
        // Move to first child
        selectNode(selectedNode!.children.first);
      }
    }
  }

  void collapseOrMoveLeft() {
    if (selectedNode == null) return;

    if (selectedNode!.children.isNotEmpty && isExpanded(selectedNode!)) {
      toggleExpanded(selectedNode!);
    } else {
      // Move to parent
      final parent = _findParent(selectedNode!);
      if (parent != null) {
        selectNode(parent);
      }
    }
  }

  WidgetData? _findParent(WidgetData target) {
    WidgetData? findParentRecursive(List<WidgetData> nodes, WidgetData? currentParent) {
      for (var node in nodes) {
        if (node.children.contains(target)) {
          return node;
        }
        final result = findParentRecursive(node.children, node);
        if (result != null) return result;
      }
      return null;
    }

    return findParentRecursive(roots, null);
  }

  void deleteSelected() {
    if (selectedNode != null) {
      bus.publish("delete", DeleteEvent(widget: selectedNode!, source: this));
    }
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
    _loadSub.cancel();
    _selectionSub.cancel();
    _propertySub.cancel();

    super.dispose();
  }
}

/// WidgetTree view
class WidgetTreeView extends StatefulWidget {
  final WidgetTreeController controller;
  final bool isActive;

  const WidgetTreeView({super.key, required this.controller, required this.isActive});

  @override
  State<WidgetTreeView> createState() => _WidgetTreeViewState();
}

class _WidgetTreeViewState extends State<WidgetTreeView> {
  // instance data

  late Environment environment;
  final FocusNode _focusNode = FocusNode();

  // override

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    environment = EnvironmentProvider.of(context);
  }

  void _onControllerUpdate() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          widget.controller.navigateUp();
        case LogicalKeyboardKey.arrowDown:
          widget.controller.navigateDown();
        case LogicalKeyboardKey.arrowRight:
          widget.controller.expandOrMoveRight();
        case LogicalKeyboardKey.arrowLeft:
          widget.controller.collapseOrMoveLeft();
        case LogicalKeyboardKey.delete:
        case LogicalKeyboardKey.backspace:
          widget.controller.deleteSelected();
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          if (widget.controller.selectedNode != null) {
            widget.controller.toggleExpanded(widget.controller.selectedNode!);
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        _handleKeyPress(event);
        return KeyEventResult.handled;
      },
      child: ListView(
            padding: const EdgeInsets.all(8),
            children: widget.controller.roots.map((node) => _buildNode(node, 0)).toList(),
          ),
        );
  }

  Widget _buildNode(WidgetData node, int depth) {
    final isExpanded = widget.controller.isExpanded(node);
    final isSelected = widget.controller.selectedNode == node;
    final hasChildren = node.children.isNotEmpty;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<WidgetData>(
          onWillAccept: (widget) => node.acceptsChild(widget!),
          onAccept: (widget) => environment
              .get<CommandStack>()
              .execute(ReparentCommand(
            bus: environment.get<MessageBus>(),
            widget: widget,
            newParent: node,
          )),
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                // Use your _getNodeBackground function
                color: isHovering
                    ? theme.colorScheme.secondary.withOpacity(0.08)
                    : _getNodeBackground(isSelected),
                borderRadius: BorderRadius.circular(6),
                border: isSelected && widget.isActive
                    ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                    : null,
              ),
              child: InkWell(
                onTap: () => widget.controller.selectNode(node),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    SizedBox(width: depth * 20),

                    // Expand/Collapse button
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: hasChildren
                          ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.controller.toggleExpanded(node),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      )
                          : const SizedBox(),
                    ),

                    const SizedBox(width: 8),

                    // Node icon
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: _getIconForNode(node),
                    ),

                    const SizedBox(width: 12),

                    // Draggable text
                    Expanded(
                      child: Draggable<WidgetData>(
                        data: node,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _getIconForNode(node),
                                const SizedBox(width: 8),
                                Text(
                                  node.type,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: Text(
                            node.type,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Text(
                          node.type,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? (widget.isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    // Children count badge
                    if (hasChildren)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${node.children.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Children
        if (hasChildren && isExpanded)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: node.children.map((c) => _buildNode(c, depth + 1)).toList(),
            ),
          ),
      ],
    );
  }

// Your existing color function (for reference)
  Color _getNodeBackground(bool isSelected) {
    if (!isSelected) return Colors.transparent;
    return widget.isActive
        ? Colors.blue.withOpacity(0.2)
        : Colors.grey.withOpacity(0.2);
  }

  /// Helper: icon per node type
  Widget _getIconForNode(WidgetData node) {
    return environment.get<TypeRegistry>().getDescriptor(node).icon;
  }
}

/// Top-level panel for the tree
class WidgetTreePanel extends StatefulWidget {
  final List<WidgetData> models;
  final VoidCallback onClose;
  final bool isActive;

  const WidgetTreePanel({required this.models, required this.onClose, required this.isActive, super.key});

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
    return PanelContainer(
      title: "editor:docks.tree.label".tr(),
      onClose: widget.onClose,
      child: Column(
        children: [
          // Tree view
          Expanded(
            child: WidgetTreeView(controller: controller, isActive: widget.isActive),
          ),
        ],
      ),
    );
  }
}

// Delete event for consistency
class DeleteEvent {
  final WidgetData widget;
  final Object source;

  DeleteEvent({required this.widget, required this.source});
}