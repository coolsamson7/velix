


import 'package:flutter/material.dart';
import 'package:velix/i18n/translator.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

import 'widget_data.dart';

class PropertyDescriptor {
  // instance data

  final String name;
  final String? i18n;
  final String? groupI18n;
  String label;
  final FieldDescriptor field;
  final String group;
  String groupLabel;
  final Type? editor;
  final bool hide;

  Type get type => field.type.type;

  // constructor

  PropertyDescriptor({required this.name, required this.field, required this.i18n, required this.group, required this.groupI18n, required this.hide, this.editor}) : label = name, groupLabel = group {
    updateI18n();
  }

  // public

  void updateI18n() {
    if ( i18n != null)
      label = Translator.tr("$i18n.label");

    if ( groupI18n != null)
      groupLabel = Translator.tr("$groupI18n.label");
  }

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
  final String? i18n;
  String label;
  final String group;
  String groupLabel;
  final IconData? icon;
  final TypeDescriptor type;
  List<PropertyDescriptor> properties;

  // constructor

  WidgetDescriptor({required this.name, required this.group, required this.type, required this.properties, required this.icon, required this.i18n}) : label = name, groupLabel = group {
    updateI18n();
  }

  // public

  T get<T>(dynamic instance, String property) {
    return type.get<T>(instance, property);
  }

  void set(dynamic instance, String property, dynamic value) {
    type.set(instance, property, value);
  }

  void updateI18n() {
    if ( i18n!= null)
      label = Translator.tr(i18n!);

    for ( var property in properties)
      property.updateI18n();
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
