
// annotation

import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';

import 'type_registry.dart';

class DeclareWidget extends ClassAnnotation {
  // instance data

  final String name;
  final String? label;
  final String? i18n;
  final String group;
  final IconData? icon;

  // constructor

  const DeclareWidget({required this.name, required this.group, required this.icon, this.label, this.i18n});

  // override

  @override
  void apply(TypeDescriptor type) {
    TypeRegistry.declare(type);
  }
}

class DeclareProperty extends FieldAnnotation {
  // instance data

  final String group;
  final String? groupI18N;
  final Type? editor;
  final String? i18n;
  final String? label;
  final bool hide;

  // constructor

  const DeclareProperty({this.group = "", this.hide = false, this.editor, this.label, this.i18n, this.groupI18N});

  // override

  @override
  void apply(TypeDescriptor type, FieldDescriptor field) {}
}