import 'dart:async';

import 'package:flutter/material.dart';

import '../components/panel_header.dart';
import '../event/events.dart';
import '../metadata/widget_data.dart';
import '../metadata/widgets/container.dart';
import '../provider/environment_provider.dart';
import '../util/message_bus.dart';


class WidgetTreeNode extends StatefulWidget {
  // instance data

  final WidgetData model;

  // constructor

  const WidgetTreeNode({super.key, required this.model});

  // override

  @override
  State<WidgetTreeNode> createState() => _WidgetTreeNodeState();
}

class _WidgetTreeNodeState extends State<WidgetTreeNode> {
  // instance data

  bool expanded = true;
  bool selected = false;
  late final MessageBus bus;
  late final StreamSubscription<SelectionEvent> subscription;

  // internal

  void select(SelectionEvent event) {
    var newSelected = identical(event.selection, widget.model);
    if (newSelected != selected) {
      setState(() {
        selected = newSelected;
      });
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();

    subscription = bus.subscribe<SelectionEvent>(
      "selection",
          (event) => select(event),
    );
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren =
        widget.model is ContainerWidgetData &&
            (widget.model as ContainerWidgetData).children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => bus.publish(
            "selection",
            SelectionEvent(selection: widget.model, source: this),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: selected ? Colors.blue.shade100 : null,
            child: Row(
              children: [
                if (hasChildren)
                  GestureDetector(
                    onTap: () {
                      setState(() => expanded = !expanded);
                    },
                    child: Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                Text(widget.model.type),
              ],
            ),
          ),
        ),
        if (hasChildren && expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (widget.model as ContainerWidgetData).children
                  .map((child) => WidgetTreeNode(model: child))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class WidgetTreePanel extends StatelessWidget {
  // instance data

  final List<WidgetData> models;

  // constructor

  const WidgetTreePanel({super.key, required this.models});

  // override

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey.shade100,
      child: PanelContainer(
        title: "Tree",
        onClose: () => {},
        child: ListView(
          children: models
              .map((model) => WidgetTreeNode(model: model))
              .toList(),
        ),
      ),
    );
  }
}