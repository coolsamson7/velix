import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix_editor/event/events.dart';
import 'package:velix_editor/util/message_bus.dart';

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

  final MessageBus messageBus;

  // constructor

  EditorCanvas({super.key, required this.models, required this.typeRegistry, required this.messageBus}) {
    for ( var model in models)
      linkParents(model);
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
  EditWidgetState? selection;

  // internal

  void select(WidgetData? widget) {
    if (selection != null)
      selection!.setSelected(false);

    if (widget != null) {
      selection = widget.widget;

      selection!.setSelected(true);
    }
  }

  void changed(PropertyChangeEvent event) {
    event.widget?.widget?.setState(() {});
  }


  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final logicalKey = event.logicalKey;

      if (logicalKey == LogicalKeyboardKey.arrowUp) {
        print("Arrow Up pressed");
      }
      else if (logicalKey == LogicalKeyboardKey.arrowDown) {
        print("Arrow Down pressed");
      }
      else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
        print("Arrow Left pressed");
      }
      else if (logicalKey == LogicalKeyboardKey.arrowRight) {
        print("Arrow Right pressed");
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