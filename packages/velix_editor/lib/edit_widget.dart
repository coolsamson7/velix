
import 'dart:async';

import 'package:flutter/material.dart' hide Theme, MetaData;


import 'event/events.dart';
import 'metadata/metadata.dart';
import 'metadata/widget_data.dart';
import 'provider/environment_provider.dart';
import 'theme/theme.dart';
import 'util/message_bus.dart';

/// Extracted draggable border wrapper
class DraggableWidgetBorder extends StatelessWidget {
  final Widget child;
  final bool selected;
  final String name;
  final WidgetData data;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;

  const DraggableWidgetBorder({
    super.key,
    required this.child,
    required this.name,
    required this.data,
    required this.selected,
    this.onDelete,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget bordered = GestureDetector(
      onTap: onSelect,
      child: _buildBorderedChild(),
    );

    // Only make draggable when selected
    if (selected) {
      bordered = LongPressDraggable<WidgetData>(
        data: data,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.7,
            child: _buildBorderedChild(),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildBorderedChild(),
        ),
        child: bordered,
      );
    }

    return bordered;
  }

  Widget _buildBorderedChild() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: selected
              ? BoxDecoration(
            border: Border.all(
              color: Colors.blue.withOpacity(0.5),
              width: 2,
            ),
          )
              : null,
          child: child,
        ),
        if (selected) ..._buildHandlesAndLabels(),
      ],
    );
  }

  List<Widget> _buildHandlesAndLabels() {
    return [
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
      Positioned(
        top: -18,
        left: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: Colors.blue.withOpacity(0.3),
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
      if (onDelete != null)
        Positioned(
          top: -18,
          right: 0,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              color: Colors.red.withOpacity(0.3),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
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


class EditWidget extends StatefulWidget {
  // instance data

  final WidgetData model;
  final MetaData meta;
  final WidgetData? parent; // optional reference to parent container

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
  // instance data

  late final Theme theme;
  late final MessageBus bus;
  bool selected = false;

  late final StreamSubscription selectionSubscription;
  late final StreamSubscription propertyChangeSubscription;

  // internal

  void select(SelectionEvent event) {
    var newSelected = identical(event.selection, widget.model);
    if (newSelected != selected) {
      setState(() {
        selected = newSelected;
      });
    }
  }

  void changed(PropertyChangeEvent event) {
    if (event.widget == widget.model) {
      setState(() {});
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var environment = EnvironmentProvider.of(context);
    theme = environment.get<Theme>();
    bus = environment.get<MessageBus>();

    selectionSubscription = bus.subscribe<SelectionEvent>("selection", (event) => select(event));
    propertyChangeSubscription = bus.subscribe<PropertyChangeEvent>(
      "property-changed",
          (event) => changed(event),
    );
  }

  @override
  void dispose() {
    super.dispose();

    selectionSubscription.cancel();
    propertyChangeSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    print("create ${widget.model.type}, selected: $selected");

    return DraggableWidgetBorder(
        name: widget.model.type,
        selected: selected,
        onDelete: () => {}, // TODO
        onSelect: () => bus.publish(
          "selection",
          SelectionEvent(selection: widget.model, source: this),
        ),
        data: widget.model,
        child: theme.builder(widget.model.type, edit: true).create(widget.model)
    );
  }
}