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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Visual child (display only, doesn't block taps)
        IgnorePointer(ignoring: true, child: visualChild),

        // GestureDetector covering exactly the child area
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => bus.publish(
              "selection",
              SelectionEvent(selection: widget.model, source: this),
            ),
          ),
        ),

        // Draggable handle (top-left corner)
        if (selected)
          Positioned(
            top: 0,
            left: 0,
            child: LongPressDraggable<WidgetData>(
              data: widget.model,
              feedback: Material(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.grey.shade200,
                  child: Text(widget.model.type),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.5, child: visualChild),
              child: Container(width: 20, height: 20, color: Colors.transparent),
            ),
          ),

        // Selection border, delete button, handles
        if (selected) ..._buildHandlesAndLabels(),
      ],
    );
  }

  List<Widget> _buildHandlesAndLabels() {
    const double tabHeight = 20;
    const double borderWidth = 2;

    return [
      // Top label
      Positioned(
        top: -(tabHeight + borderWidth),
        left: 0,
        child: Container(
          height: tabHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: Colors.blue.withOpacity(0.7),
          child: Text(
            widget.model.type,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ),

      // Delete button
      Positioned(
        top: -(tabHeight + borderWidth),
        right: 0,
        child: GestureDetector(
          onTap: delete,
          behavior: HitTestBehavior.translucent,
          child: Container(
            height: tabHeight,
            width: tabHeight,
            alignment: Alignment.center,
            color: Colors.red.withOpacity(0.7),
            child: const Icon(Icons.close, size: 12, color: Colors.white),
          ),
        ),
      ),

      // Small handles
      Positioned(
        top: -4,
        left: 0,
        right: 0,
        child: Align(alignment: Alignment.topCenter, child: _buildHandle()),
      ),
      Positioned(
        bottom: -4,
        left: 0,
        right: 0,
        child: Align(alignment: Alignment.bottomCenter, child: _buildHandle()),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        left: -4,
        child: Align(alignment: Alignment.centerLeft, child: _buildHandle()),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: -4,
        child: Align(alignment: Alignment.centerRight, child: _buildHandle()),
      ),
    ];
  }

  Widget _buildHandle() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.5),
        shape: BoxShape.rectangle,
      ),
    );
  }
}
