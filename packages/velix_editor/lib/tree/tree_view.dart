import 'dart:async';
import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/type_registry.dart';

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

    environment = EnvironmentProvider.of(context);
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
           onWillAccept: (widgetData) => node.acceptsChild(widgetData!),
           onAccept: (widgetData) => environment.get<CommandStack>().execute(
             ReparentCommand(
               bus: environment.get<MessageBus>(),
               widget: widgetData,
               newParent: node,
             ),
           ),
           builder: (context, candidateData, rejectedData) {
             final isHovering = candidateData.isNotEmpty;

             return GestureDetector(
               onTap: () => widget.controller.selectNode(node),
               child: Container(
                 decoration: BoxDecoration(
                   color: isSelected ? Colors.blue.withOpacity(0.2) : null,
                   border: isHovering ? Border.all(color: Colors.green, width: 2) : null,
                 ),
                 padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                 child: Row(
                   children: [
                     SizedBox(width: depth * 16),

                     // Leading icon
                     SizedBox(
                       width: 16,
                       height: 16,
                       child: Icon(
                         _getIconForNode(node),
                         size: 16,
                         color: Colors.grey.shade700,
                       ),
                     ),

                     const SizedBox(width: 4),

                     // Chevron for expanding
                     if (hasChildren)
                       GestureDetector(
                         behavior: HitTestBehavior.translucent,
                         onTap: () => widget.controller.toggleExpanded(node),
                         child: SizedBox(
                           width: 16,
                           height: 16,
                           child: Icon(
                             isExpanded ? Icons.expand_more : Icons.chevron_right,
                             size: 16,
                           ),
                         ),
                       )
                     else
                       const SizedBox(width: 16),

                     const SizedBox(width: 4),

                     // Node label + draggable
                     Expanded(
                       child: Draggable<WidgetData>(
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
           Padding(
             padding: const EdgeInsets.only(left: 24),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: node.children.map((c) => _buildNode(c, depth + 1)).toList(),
             ),
           ),
       ],
     );
   }

   /// Helper: icon per node type
   IconData _getIconForNode(WidgetData node) {
    return environment.get<TypeRegistry>().getMetaData(node).icon!;
     switch (node.type) {
       case "container":
         return Icons.view_column;
       case "text":
         return Icons.text_fields;
       case "button":
         return Icons.smart_button;
       default:
         return Icons.widgets;
     }
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
