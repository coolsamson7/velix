


import 'package:flutter/material.dart';
import 'package:velix/i18n/translator.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_mapper/mapper/json.dart';

import 'annotations.dart';
import 'widget_data.dart';

class PropertyDescriptor {
  // instance data

  final DeclareProperty annotation;

  final String name;

  String label = "";
  final FieldDescriptor field;
  String group = "";
  final Type? editor; // TODO
  final bool hide;

  dynamic defaultValue = null;

  Type get type => field.type.type;

  Type? get validator => annotation.validator;

  TypeDescriptor getTypeDescriptor() => field.typeDescriptor;

  T? get<T>(dynamic object) => field.get(object);

  void set<T>(T object, dynamic value) => field.set(object, value);

  // constructor

  PropertyDescriptor({required this.name, required this.annotation, required this.field,  this.hide = false, this.editor}) {
      try {
        defaultValue = getTypeDescriptor().constructorParameters
            .firstWhere((param) => param.name == name)
            .defaultValue;
      }
      catch (e) {
        print(1);
      }
  }

  // public

  void updateI18n(String widget) {
    label = Translator.tr("editor:widgets.$widget.$name.label");
    group = Translator.tr("editor:groups.${annotation.group}.label");
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

    if (field.factoryConstructor != null)
      return field.factoryConstructor!();

    if (field.type is ObjectType)
      return (field.type as ObjectType).typeDescriptor.constructor!();

    //if (defaultValue != null)
      return defaultValue; // e.g. enums

    // children...

    //return field.factoryConstructor!();
  }
}

// we will use that for generic property panels
class WidgetDescriptor {
  // instance data

  DeclareWidget annotation;

  String label = "";
  String group = "";

  final Widget icon;
  final TypeDescriptor type;
  Map<String,PropertyDescriptor> properties;

  String get name => annotation.name;

  // constructor

  WidgetDescriptor({required this.annotation, required this.type, required List<PropertyDescriptor> properties, required this.icon})
  : properties = {for (var p in properties) p.name: p}
  {
    updateI18n();
  }

  // public

  PropertyDescriptor getProperty(String name) => properties[name]!;

  T get<T>(dynamic instance, String property) {
    return type.get<T>(instance, property);
  }

  void set(dynamic instance, String property, dynamic value) {
    type.set(instance, property, value);
  }

  void updateI18n() {
    label = Translator.tr("editor:widgets.$name.title");
    group = Translator.tr("editor:widget.groups.${annotation.group}.label");

    for ( var property in properties.values)
      property.updateI18n(name);
  }

  WidgetData create() {
    Map<String, dynamic> args = {};

    // fetch defaults

    for (var property in properties.values)
      args[property.name] = property.field.isNullable ? null : property.createDefault();

    // done

    return type.fromMapConstructor!(args);
  }

  T parse<T>(Map<String, dynamic> data) {
    return JSON.deserialize<T>(data);
  }
}
