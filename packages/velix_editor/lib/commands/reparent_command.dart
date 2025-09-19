

import '../event/events.dart';
import '../metadata/widget_data.dart';
import '../util/message_bus.dart';
import 'command.dart';

class ReparentCommand extends Command {
  // instance data

  final MessageBus bus;
  final WidgetData widget;
  int index = -1;
  final WidgetData? oldParent;
  final WidgetData? newParent;

  // constructor

  ReparentCommand({
    required this.bus,
    required this.widget,
    required this.newParent,
  }) : oldParent = widget.parent;

  // override

  @override
  void execute() {
    // remove from old

    if ( oldParent != null) {
      index = oldParent!.children.indexOf(widget);
      oldParent!.children.remove(widget);

      bus.publish(
        "property-changed",
        PropertyChangeEvent(widget: oldParent, source: this),
      );
    }

    // add to new

    widget.parent = newParent;

    if ( newParent != null) {
      newParent!.children.add(widget);

      bus.publish(
        "property-changed",
        PropertyChangeEvent(widget: newParent, source: this),
      );
    }
  }

  @override
  void undo({bool deleteOnly = false}) {
    // remove from parent

    if ( newParent != null) {
      newParent!.children.remove(widget);

      bus.publish(
        "property-changed",
        PropertyChangeEvent(widget: newParent, source: this),
      );
    }

    widget.parent = oldParent;

    // add to old

    if (oldParent != null) {
      if ( index >= 0)
        oldParent!.children.insert(index, widget);
      else
        oldParent!.children.add(widget);

      bus.publish(
        "property-changed",
        PropertyChangeEvent(widget: oldParent, source: this),
      );
    }

    super.undo(deleteOnly: deleteOnly);
  }
}