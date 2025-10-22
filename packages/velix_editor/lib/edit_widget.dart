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
  final WidgetData model;

  EditWidget({required this.model})
      : super(key: ValueKey(model.id));

  @override
  State<EditWidget> createState() => EditWidgetState();
}

class EditWidgetState extends AbstractEditorWidgetState<EditWidget> {
  late final Environment environment;
  late final WidgetFactory theme;
  bool selected = false;
  bool isHovered = false;

  void _moveWidget(Direction direction) {
    int index = widget.model.index();

    switch (direction) {
      case Direction.left:
      case Direction.up:
        index -= 1;
        break;
      case Direction.right:
      case Direction.down:
        index += 1;
        break;
    }

    environment.get<CommandStack>().execute(
      ReparentCommand(
        bus: environment.get<MessageBus>(),
        widget: widget.model,
        newParent: widget.model.parent,
        newIndex: index,
      ),
    );

    setSelected(true);
  }

  void setSelected(bool value) {
    if (value != selected && widget.model.widget != null) {
      if (!mounted)
        print("woa");
      setState(() => selected = value);
    }
  }

  void delete() {
    environment
        .get<CommandStack>()
        .execute(ReparentCommand(bus: environment.get<MessageBus>(), widget: widget.model, newParent: null));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    environment = EnvironmentProvider.of(context);
    theme = environment.get<WidgetFactory>();
  }

  @override
  Widget build(BuildContext context) {
    final visualChild = theme.builder(widget.model.type, edit: true).create(widget.model, environment, context);
    widget.model.widget = this;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Draggable<WidgetData>(
            data: widget.model,
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
            childWhenDragging: Opacity(opacity: 0.5, child: visualChild),
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
                  visualChild,
                  if (selected || isHovered)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? Colors.blue.withOpacity(0.8) : Colors.blue.withOpacity(0.4),
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (selected) ..._buildNonDeleteControls(),
                ],
              ),
            ),
          ),

          // Delete (X) button — visible on hover
          if (selected && isHovered)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: delete,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(1, 1)),
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
      Positioned(
        top: -(controlHeight + borderWidth),
        left: 0,
        child: Container(
          height: controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
          child: Center(
            child: Text(
              widget.model.type,
              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      // move handles now only visible when hovered
      if (isHovered) ..._buildMoveHandles(),
    ];
  }

  List<Widget> _buildMoveHandles() {
    const double handleSize = 16;

    Widget moveArrow(IconData icon, Direction direction) {
      final bool enabled = widget.model.canMove(direction);
      if (!enabled) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => _moveWidget(direction),
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: handleSize,
            height: handleSize,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.9),
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(2), // rectangular
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 12, color: Colors.white),
          ),
        ),
      );
    }

    return [
      Positioned(
        top: 4,
        left: 0,
        right: 0,
        child: Align(alignment: Alignment.topCenter, child: moveArrow(Icons.keyboard_arrow_up, Direction.up)),
      ),
      Positioned(
        bottom: 4,
        left: 0,
        right: 0,
        child: Align(alignment: Alignment.bottomCenter, child: moveArrow(Icons.keyboard_arrow_down, Direction.down)),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        left: 4,
        child: Align(alignment: Alignment.centerLeft, child: moveArrow(Icons.keyboard_arrow_left, Direction.left)),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: 4,
        child: Align(alignment: Alignment.centerRight, child: moveArrow(Icons.keyboard_arrow_right, Direction.right)),
      ),
    ];
  }
}
