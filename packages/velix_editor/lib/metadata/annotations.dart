
// annotation

import 'package:velix/reflectable/reflectable.dart';

import 'type_registry.dart';

/// Annotation used to annotate [WidgetData] classes.
class DeclareWidget extends ClassAnnotation {
  // instance data

  final String name;
  final String group;
  final String icon; // IconData? or String?

  // constructor

  /// Create a new [DeclareWidget]
  /// [name] name of the widget
  /// [group] group name of the widget
  /// [icon] icon name of the widget
  const DeclareWidget({required this.name, required this.group, required this.icon});

  // override

  @override
  void apply(TypeDescriptor type) {
    TypeRegistry.declare(type);
  }
}

/// Annotation used to annotate [WidgetData] properties
class DeclareProperty extends FieldAnnotation {
  // instance data

  final String group;
  final Type? editor;
  final String? label;
  final bool hide;
  final Type? validator;

  // constructor

  /// Create a new [DeclareProperty]
  /// [group] the group name of the property which will be used by the property panel
  /// [hide] if [true] the property is not displayed in the property panel
  /// [editor] optional [PropertyEditorBuilder] type that will be used to create the editor
  /// [label] the label of the property. This is actually a i18n key
  /// [validator] optional [PropertyValidator] class used to validate the property.
  const DeclareProperty({this.group = "", this.hide = false, this.editor, this.label, this.validator});

  // override

  @override
  void apply(TypeDescriptor type, FieldDescriptor field) {}
}