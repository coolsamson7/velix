
// annotation

import 'package:velix/reflectable/reflectable.dart';

import 'type_registry.dart';

class DeclareWidget extends ClassAnnotation {
  // instance data

  final String name;
  final String group;
  final String icon; // IconData? or String?

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
  final Type? editor;
  final String? label;
  final bool hide;
  final Type? validator;

  // constructor

  const DeclareProperty({this.group = "", this.hide = false, this.editor, this.label, this.validator});

  // override

  @override
  void apply(TypeDescriptor type, FieldDescriptor field) {}
}