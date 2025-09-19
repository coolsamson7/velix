

import '../event/events.dart';
import '../metadata/metadata.dart';
import '../metadata/widget_data.dart';
import '../util/message_bus.dart';
import 'command.dart';

class ReparentCommand extends Command {
  // instance data

  final MessageBus bus;
  final WidgetData widget;
  final WidgetData? oldParent;
  final WidgetData? newParent;

  // constructor

  ReparentCommand({
    required this.bus,
    required this.widget,
    required this.oldParent,
    required this.newParent,
  });

  // override

  @override
  void execute() {
    // remove from old

    if ( oldParent != null) {
      oldParent!.children.remove(widget);
    }

    // add to new

    if ( newParent != null) {
      newParent!.children.add(widget);
      widget.parent = newParent;
    }
  }

  @override
  void undo({bool deleteOnly = false}) {
    // remove from parent

    if ( newParent != null)
      newParent!.children.remove(widget);

    bus.publish(
      "property-changed",
      PropertyChangeEvent(widget: newParent, source: this),
    );

    // add to old

    if (oldParent != null) {
      oldParent!.children.add(widget);
      widget.parent = oldParent;
    }

    // bus?

    bus.publish(
      "property-changed",
      PropertyChangeEvent(widget: oldParent, source: this),
    );

    super.undo(deleteOnly: deleteOnly);
  }
}