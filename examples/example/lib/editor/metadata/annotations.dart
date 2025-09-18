
// annotation

import 'package:sample/editor/metadata/type_registry.dart';
import 'package:velix/reflectable/reflectable.dart';

class DeclareWidget extends ClassAnnotation {
  // instance data

  final String name;
  final String group;

  // constructor

  const DeclareWidget({required this.name, required this.group});

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

  const DeclareProperty({required this.group, this.hide = false});

  // override

  @override
  void apply(TypeDescriptor type, FieldDescriptor field) {}
}