

import '../event/events.dart';
import '../metadata/metadata.dart';
import '../metadata/widget_data.dart';
import '../util/message_bus.dart';
import 'command.dart';

class PropertyChangeCommand<T> extends Command {
  // instance data

  final MessageBus bus;
  final WidgetDescriptor descriptor;
  final Object target;
  final String property;
  final T oldValue;
  late T _newValue;

  set value(dynamic value) {
    _newValue = value;
    descriptor.set(target, property, value);

    bus.publish(
      "property-changed",
      PropertyChangeEvent(widget: target as WidgetData, source: this),
    );
  }

  // constructor

  PropertyChangeCommand({
    required this.bus,
    required this.descriptor,
    required this.target,
    required this.property,
    required dynamic newValue,
  }) : oldValue = descriptor.get(target, property) as T {
    _newValue = newValue;
  }

  // override

  @override
  void execute() {
    value = _newValue;
  }

  @override
  void undo({bool deleteOnly = false}) {
    descriptor.set(target, property, oldValue);

    bus.publish(
      "property-changed",
      PropertyChangeEvent(widget: target as WidgetData, source: this),
    );

    super.undo(deleteOnly: deleteOnly);
  }
}