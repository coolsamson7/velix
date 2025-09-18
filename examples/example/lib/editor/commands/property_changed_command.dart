
import 'package:sample/editor/metadata/widget_data.dart';
import 'package:sample/editor/util/message_bus.dart';

import '../event/events.dart';
import '../metadata/metadata.dart';
import 'command.dart';

class PropertyChangeCommand<T> extends Command {
  // instance data

  final MessageBus bus;
  final MetaData metaData;
  final Object target;
  final String property;
  final T oldValue;
  late final T _newValue;

  set value(dynamic value) {
    _newValue = value;
    metaData.set(target, property, value);

    bus.publish(
      "property-changed",
      PropertyChangeEvent(widget: target as WidgetData, source: this),
    );
  }

  // constructor

  PropertyChangeCommand({
    required this.bus,
    required this.metaData,
    required this.target,
    required this.property,
    required dynamic newValue,
  }) : oldValue = metaData.get(target, property) as T {
    _newValue = newValue;
  }

  // override

  @override
  void execute() {
    value = _newValue;
  }

  @override
  void undo() {
    metaData.set(target, property, oldValue);

    bus.publish(
      "property-changed",
      PropertyChangeEvent(widget: target as WidgetData, source: this),
    );

    super.undo();
  }
}