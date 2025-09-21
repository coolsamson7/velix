
// annotation

import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';

import 'type_registry.dart';

class DeclareWidget extends ClassAnnotation {
  // instance data

  final String name;
  final String group;
  final IconData? icon;

  // constructor

  const DeclareWidget({required this.name, required this.group, required this.icon});

  // override

  @override
  void apply(TypeDescriptor type) {
    TypeRegistry.declare(type);
  }
}

class DeclareProperty extends FieldAnnotation {
  // instance data

  final String group;
  final bool hide;

  // constructor

  const DeclareProperty({this.group = "", this.hide = false});

  // override

  @override
  void apply(TypeDescriptor type, FieldDescriptor field) {}
}