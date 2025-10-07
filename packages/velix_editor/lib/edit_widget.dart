import 'package:flutter/material.dart' hide WidgetState;
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/commands/command_stack.dart';
import 'package:velix_editor/event/events.dart';
import 'package:velix_editor/theme/abstract_widget.dart';
import 'package:velix_editor/theme/theme.dart';
import 'package:velix_editor/util/message_bus.dart';
import 'package:velix_ui/provider/environment_provider.dart';

import '../../metadata/widget_data.dart';
import 'commands/reparent_command.dart';

class EditWidget extends StatefulWidget {
  // instance data

  final WidgetData model;

  // constructor

  const EditWidget({super.key, required this.model});

  // override

  @override
  State<EditWidget> createState() => EditWidgetState();
}

class EditWidgetState extends AbstractWidgetState<EditWidget> {
  // instance data

  late final Environment environment;
  late final WidgetFactory theme;
  bool selected = false;
  bool isHovered = false;

  // internal

  void setSelected(bool value) {
    if (value != selected)
      if (widget.model.widget != null) // was it deleted?
        setState(() => selected = value);
  }

  void delete() {
    environment.get<CommandStack>().execute(
      ReparentCommand(bus: environment.get<MessageBus>(), widget: widget.model, newParent: null),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    theme = environment.get<WidgetFactory>();
  }


  @override
  Widget build(BuildContext context) {
    final visualChild = theme.builder(widget.model.type, edit: true)
        .create(widget.model, environment, context);

    widget.model.widget = this;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The draggable widget
          Draggable<WidgetData>(
            data: widget.model,
            onDragStarted: () {
              print('Drag started for: ${widget.model.type}');
            },
            onDragEnd: (details) {
              print('Drag ended for: ${widget.model.type}');
            },
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Moving ${widget.model.type}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  visualChild,
                  // Show dashed border when dragging
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.5),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                environment.get<MessageBus>().publish(
                  "selection",
                  SelectionEvent(selection: widget.model, source: this),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The actual widget content (made non-interactive by the builders)
                  visualChild,

                  // Selection border
                  if (selected || isHovered)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected
                                  ? Colors.blue.withOpacity(0.8)
                                  : Colors.blue.withOpacity(0.4),
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Type label and resize handles only
                  if (selected) ..._buildNonDeleteControls(),
                ],
              ),
            ),
          ),

          // Delete button - only visible on hover
          if (selected && isHovered)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  delete();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildNonDeleteControls() {
    const double controlHeight = 24;
    const double borderWidth = 2;

    return [
      // Type label - back to original position
      Positioned(
        top: -(controlHeight + borderWidth),
        left: 0,
        child: Container(
          height: controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Center(
            child: Text(
              widget.model.type,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),

      // Resize handles
      ..._buildResizeHandles(),
    ];
  }

  List<Widget> _buildResizeHandles() {
    const double handleSize = 10;

    Widget cornerHandle() => Container(
      width: handleSize,
      height: handleSize,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
    );

    Widget moveArrow(IconData icon, {required bool enabled}) {
      return Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          width: handleSize * 2,
          height: handleSize * 2,
          decoration: BoxDecoration(
            color: enabled ? Colors.blue.withOpacity(0.9) : Colors.grey.shade500,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
            ],
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
      );
    }

    return [
      // --- Corners (always visible)
      Positioned(top: -4, left: -4, child: cornerHandle()),
      Positioned(top: -4, right: -4, child: cornerHandle()),
      Positioned(bottom: -4, left: -4, child: cornerHandle()),
      Positioned(bottom: -4, right: -4, child: cornerHandle()),

      // --- Midpoint directional handles (show movement availability)
      if (widget.model.canMove(Direction.up))
        Positioned(
          top: -14,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: moveArrow(Icons.keyboard_arrow_up, enabled: true),
          ),
        ),
      if (widget.model.canMove(Direction.down))
        Positioned(
          bottom: -14,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: moveArrow(Icons.keyboard_arrow_down, enabled: true),
          ),
        ),
      if (widget.model.canMove(Direction.left))
        Positioned(
          top: 0,
          bottom: 0,
          left: -14,
          child: Align(
            alignment: Alignment.centerLeft,
            child: moveArrow(Icons.keyboard_arrow_left, enabled: true),
          ),
        ),
      if (widget.model.canMove(Direction.right))
        Positioned(
          top: 0,
          bottom: 0,
          right: -14,
          child: Align(
            alignment: Alignment.centerRight,
            child: moveArrow(Icons.keyboard_arrow_right, enabled: true),
          ),
        ),
    ];
  }

}