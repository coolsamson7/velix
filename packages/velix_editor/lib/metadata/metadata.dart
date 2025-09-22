


import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import 'widget_data.dart';

class Property {
  // instance data

  final String name;
  final String label;
  final FieldDescriptor field;
  final String group;
  final bool hide;

  Type get type => field.type.type;

  // constructor

  Property({required this.name, required this.field, required this.label, required this.group, required this.hide});

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
class WidgetDescriptor {
  // instance data

  final String name;
  final String group;
  final IconData? icon;
  final TypeDescriptor type;
  List<Property> properties;

  // constructor

  WidgetDescriptor({required this.name, required this.group, required this.type, required this.properties, required this.icon});

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
      args[property.name] = property.field.isNullable ? null : property.createDefault();

    // done

    return type.fromMapConstructor!(args);
  }

  T parse<T>(Map<String, dynamic> data) {
    return JSON.deserialize<T>(data);
  }
}
