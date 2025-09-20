import 'dart:async';
import 'package:flutter/material.dart' hide Theme, MetaData;
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/commands/command_stack.dart';
import 'package:velix_editor/event/events.dart';
import 'package:velix_editor/theme/theme.dart';
import 'package:velix_editor/util/message_bus.dart';
import 'package:velix_ui/provider/environment_provider.dart';

import '../../metadata/widget_data.dart';
import 'commands/reparent_command.dart';
import 'metadata/metadata.dart';

class EditWidget extends StatefulWidget {
  final WidgetData model;
  final WidgetDescriptor meta;
  final WidgetData? parent;

  const EditWidget({
    super.key,
    required this.model,
    required this.meta,
    this.parent,
  });

  @override
  State<EditWidget> createState() => _EditWidgetState();
}

class _EditWidgetState extends State<EditWidget> {
  late final Environment environment;
  late final WidgetFactory theme;
  late final MessageBus bus;
  bool selected = false;
  bool isHovered = false;

  late final StreamSubscription selectionSubscription;
  late final StreamSubscription propertyChangeSubscription;

  void select(SelectionEvent event) {
    final newSelected = identical(event.selection, widget.model);
    if (newSelected != selected) {
      setState(() => selected = newSelected);
    }
  }

  void changed(PropertyChangeEvent event) {
    if (event.widget == widget.model) setState(() {});
  }

  void delete() {
    environment.get<CommandStack>().execute(
      ReparentCommand(bus: bus, widget: widget.model, newParent: null),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    theme = environment.get<WidgetFactory>();
    bus = environment.get<MessageBus>();

    selectionSubscription = bus.subscribe<SelectionEvent>("selection", select);
    propertyChangeSubscription = bus.subscribe<PropertyChangeEvent>("property-changed", changed);
  }

  @override
  void dispose() {
    selectionSubscription.cancel();
    propertyChangeSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualChild = theme.builder(widget.model.type, edit: true)
        .create(widget.model, environment);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Draggable<WidgetData>(
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
            bus.publish(
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

              // Selection controls - only when selected
              if (selected) ..._buildSelectionControls(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSelectionControls() {
    const double controlHeight = 24;
    const double borderWidth = 2;

    return [
      // Type label
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

      // Delete button
      Positioned(
        top: -(controlHeight + borderWidth),
        right: 0,
        child: GestureDetector(
          onTap: delete,
          child: Container(
            height: controlHeight,
            width: controlHeight,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
              ),
            ),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),

      // Resize handles
      ..._buildResizeHandles(),
    ];
  }

  List<Widget> _buildResizeHandles() {
    const double handleSize = 8;

    Widget buildHandle() {
      return Container(
        width: handleSize,
        height: handleSize,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    return [
      // Corner handles
      Positioned(top: -4, left: -4, child: buildHandle()),
      Positioned(top: -4, right: -4, child: buildHandle()),
      Positioned(bottom: -4, left: -4, child: buildHandle()),
      Positioned(bottom: -4, right: -4, child: buildHandle()),

      // Mid-point handles
      Positioned(
        top: -4, left: 0, right: 0,
        child: Align(alignment: Alignment.topCenter, child: buildHandle()),
      ),
      Positioned(
        bottom: -4, left: 0, right: 0,
        child: Align(alignment: Alignment.bottomCenter, child: buildHandle()),
      ),
      Positioned(
        top: 0, bottom: 0, left: -4,
        child: Align(alignment: Alignment.centerLeft, child: buildHandle()),
      ),
      Positioned(
        top: 0, bottom: 0, right: -4,
        child: Align(alignment: Alignment.centerRight, child: buildHandle()),
      ),
    ];
  }
}