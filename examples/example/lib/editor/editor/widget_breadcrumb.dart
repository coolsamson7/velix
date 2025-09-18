import 'dart:async';

import 'package:flutter/material.dart';

import '../components/breadcrumb.dart';
import '../event/events.dart';
import '../metadata/widget_data.dart';
import '../provider/environment_provider.dart';
import '../util/message_bus.dart';

/// Panel that listens to the MessageBus and displays the current selection as a thumbnail.
/// Shows only the selected item (no hierarchy).
class WidgetBreadcrumbWidget extends StatefulWidget {
  // constructor

  const WidgetBreadcrumbWidget({super.key});

  // override

  @override
  State<WidgetBreadcrumbWidget> createState() => _WidgetBreadcrumbState();
}

class _WidgetBreadcrumbState extends State<WidgetBreadcrumbWidget> {
  // instance data

  WidgetData? _selected;
  late final MessageBus _bus;
  StreamSubscription<SelectionEvent>? _subscription;

  // internal

  void select(WidgetData widget) {
    _bus.publish("selection", SelectionEvent(selection: widget, source: this));
  }

  List<BreadcrumbItem> buildBreadcrumbs(WidgetData widget) {
    List<BreadcrumbItem> result = [];

    for (WidgetData? w = widget; w != null; w = w.parent)
      result.insert(0, BreadcrumbItem(label: w.type, onTap: () => select(w!)));

    // done

    return result;
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Acquire bus from environment and subscribe once
    final env = EnvironmentProvider.of(context);
    _bus = env.get<MessageBus>();

    _subscription ??= _bus.subscribe<SelectionEvent>("selection", (event) {
      // update selected item (event.selection may be null)
      setState(() => _selected = event.selection);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Breadcrumb(items: [
      if ( _selected != null ) ...buildBreadcrumbs(_selected!)
    ]);
  }
}
