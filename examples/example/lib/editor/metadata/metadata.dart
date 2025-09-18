

import 'package:sample/editor/metadata/widget_data.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

class Property {
  // instance data

  final String name;
  final FieldDescriptor field;
  final String group;
  final bool hide;

  Type get type => field.type.type;

  // constructor

  Property({required this.name, required this.field, required this.group, required this.hide});

  // public

  dynamic createDefault() {
    switch (type) {
      case String:
        return "";
      case int:
        return 0;
      case double:
        return 0.0;
      case bool:
        return false;
    }

    return field.factoryConstructor!();
  }
}

// we will use that for generic property panels
class MetaData {
  // instance data

  final String name;
  final String group;
  final TypeDescriptor type;
  List<Property> properties;

  // constructor

  MetaData({required this.name, required this.group, required this.type, required this.properties});

  // public

  T get<T>(dynamic instance, String property) {
    return type.get<T>(instance, property);
  }

  void set(dynamic instance, String property, dynamic value) {
    type.set(instance, property, value);
  }

  WidgetData create() {
    Map<String, dynamic> args = {};

    // fetch defaults

    for (var property in properties)
      args[property.name] = property.createDefault();

    // done

    return type.fromMapConstructor!(args);
  }

  T parse<T>(Map<String, dynamic> data) {
    return JSON.deserialize<T>(data);
  }
}
