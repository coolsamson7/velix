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
  const WidgetBreadcrumbWidget({super.key});

  @override
  State<WidgetBreadcrumbWidget> createState() => _WidgetBreadcrumbState();
}

class _WidgetBreadcrumbState extends State<WidgetBreadcrumbWidget> {
  WidgetData? _selected;
  late final MessageBus _bus;
  StreamSubscription<SelectionEvent>? _subscription;

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
      if ( _selected != null ) BreadcrumbItem(label: _selected!.type)
    ]);
  }
}
