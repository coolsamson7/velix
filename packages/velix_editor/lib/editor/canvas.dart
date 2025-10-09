import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix_editor/event/events.dart';
import 'package:velix_editor/util/message_bus.dart';

import '../commands/command_stack.dart';
import '../commands/reparent_command.dart';
import '../edit_widget.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';

class EditorCanvas extends StatefulWidget {
  // static

  static WidgetData linkParents(WidgetData data) {
    void link(WidgetData data, WidgetData? parent) {
      data.parent = parent;
      for (var child in data.children)
        link(child, data);
    }

    link(data, null);

    // done

    return data;
  }

  // instance data

  final List<WidgetData> models;
  final TypeRegistry typeRegistry;
  final bool isActive;
  final MessageBus messageBus;

  // constructor

  EditorCanvas({super.key, required this.models, required this.typeRegistry, required this.messageBus, required this.isActive}) {
    for ( var model in models)
      linkParents(model); // TODO doppelt?
  }

  // override

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  // instance data

  TypeRegistry? typeRegistry;
  final FocusNode _focusNode = FocusNode();
  late StreamSubscription subscription;
  late StreamSubscription propertyChangeSubscription;
  WidgetData? selection;

  // internal

  void select(WidgetData? widget) {
    if (selection != null && selection!.widget != null)
      (selection!.widget as EditWidgetState).setSelected(false);

    if (widget != null) {
      selection = widget;

      (selection!.widget as EditWidgetState).setSelected(true);
    }
  }

  void changed(PropertyChangeEvent event) {
    event.widget?.widget?.setState(() {});
  }

  void handleUp(WidgetData w) {
    if (w.canMove(Direction.up)) {
      int index = w.index();
      EnvironmentProvider.of(context).get<CommandStack>()
          .execute(ReparentCommand(
          bus: widget.messageBus,
          widget: w,
          newParent: w.parent,
          newIndex: index - 1
      ));
    }
  }

  void handleDown(WidgetData w) {
    if (w.canMove(Direction.down)) {
      int index = w.index();
      EnvironmentProvider.of(context).get<CommandStack>()
          .execute(ReparentCommand(
          bus: widget.messageBus,
          widget: w,
          newParent: w.parent,
          newIndex: index + 1
      ));
    }
  }

  void handleLeft(WidgetData w) {
    if (w.canMove(Direction.left)) {
      int index = w.index();
      EnvironmentProvider.of(context).get<CommandStack>()
          .execute(ReparentCommand(
          bus: widget.messageBus,
          widget: w,
          newParent: w.parent,
          newIndex: index - 1
      ));
    }
  }

  void handleRight(WidgetData w) {
    if (w.canMove(Direction.right)) {
      int index = w.index();
      EnvironmentProvider.of(context).get<CommandStack>()
          .execute(ReparentCommand(
          bus: widget.messageBus,
          widget: w,
          newParent: w.parent,
          newIndex: index + 1
      ));
    }
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final logicalKey = event.logicalKey;

      if (logicalKey == LogicalKeyboardKey.arrowUp) {
        if (selection != null ) handleUp(selection!);
      }
      else if (logicalKey == LogicalKeyboardKey.arrowDown) {
        if (selection != null ) handleDown(selection!);
      }
      else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (selection != null ) handleLeft(selection!);
      }
      else if (logicalKey == LogicalKeyboardKey.arrowRight) {
        if (selection != null ) handleRight(selection!);
      }
    }
  }

  // override

  @override
  void initState() {
    super.initState();

    subscription = widget.messageBus.subscribe<SelectionEvent>("selection", (event) => select(event.selection));
    propertyChangeSubscription = widget.messageBus.subscribe<PropertyChangeEvent>("property-changed", changed);
  }

  @override
  void dispose() {
    _focusNode.dispose();

    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    typeRegistry ??= EnvironmentProvider.of(context).get<TypeRegistry>();

    return DragTarget<WidgetData>(
      onWillAccept: (_) => widget.models.isEmpty,
      onAccept: (w) {
        // palette

        widget.models.add(w);
        setState(() {});
      },
      builder: (context, candidateData, rejectedData) {
        return RawKeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKey: _handleKey,
            child: Container(
              color: Colors.grey.shade200,
              child: ListView(
              children: widget.models.map((m) => Padding(
                      padding: const EdgeInsets.all(8.0), // TODO?
                      child: EditWidget(model: m),
                    ),
              ).toList(),
          ),
        )
        );
      },
    );
  }
}