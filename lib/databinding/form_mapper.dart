import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'text_adapter.dart';
import 'valued_widget.dart';

import '../reflectable/reflectable.dart';
import '../mapper/transformer.dart';
import '../validation/validation.dart';

/// @internal
class TypeProperty extends Property<ValuedWidgetContext> {
  // instance data

  final String path;
  final FieldDescriptor field;

  final List<TypeProperty> children = [];

  dynamic initialValue;
  dynamic value;

  final bool twoWay;
  TypeProperty? parent;

  // constructor

  TypeProperty({required this.field, required this.path, this.parent, this.twoWay=false}) {
    initialValue = this;
    value = this;

    if ( parent != null) {
      parent!.children.add(this);
    }
  }

  void commit(ValuedWidgetContext context) {
    if ( isDirty()) {
      callSetter(context.mapper!.instance, value, context);
    }
  }

  // internal

  bool isInitialized() {
    return initialValue != this;
  }

  bool isDirty() {
    return value != initialValue;
  }

  TypeProperty findChild(String property) {
    return children.firstWhere((child) => child.path == property);
  }

  dynamic newInstance() {
    Map<Symbol, dynamic> args = {};

    // TODO: check if not all attributes are mapped!

    for (var constructorParameter in (field.type as ObjectType).typeDescriptor.constructorParameters) {
      var name = constructorParameter.name;

      var child = findChild("$path.$name");

      args[Symbol(name)] = child.value;

      child.initialValue = child.value; // make it only happens once
    }

    return Function.apply((field.type as ObjectType).typeDescriptor.constructor, [], args);
  }

  void callSetter(dynamic instance, dynamic value, ValuedWidgetContext context) {
    if (parent != null)
      instance = parent!.get(instance, context);

    if ( field.isFinal ) {
      // i need to construct a new instance of my parent, given all values

      parent!.callSetter(context.mapper!.instance, parent!.newInstance(), context); // TODO: check recursive
    } // if
    else {
      field.setter!(instance, initialValue = value);
    }
  }

  // implement

  @override
  dynamic get(dynamic instance, ValuedWidgetContext context) {
    if (!isInitialized()) {
      if (parent != null) {
        instance = parent!.get(instance, context);
      }

      value = initialValue = field.getter(instance);
    }

    return value;
  }

  @override
  void set(dynamic instance, dynamic value, ValuedWidgetContext context) {
    if (this.value != value) {
      var wasDirty = isDirty();

      if (parent != null)
        instance = parent!.get(instance, context);

      this.value = value;

      if (twoWay) {
        initialValue = value;

        callSetter(instance, value, context);
      }

      var newDirty = isDirty();

      if (wasDirty != newDirty)
        context.mapper!.addDirty(wasDirty ? -1 : 1);
    } // if
  }
}

/// A [FormMapper] is used to bind field values to form elements
class FormMapper {
  // instance data

  final dynamic instance;
  late TypeDescriptor type;
  final List<Operation<ValuedWidgetContext>> operations = [];
  late Transformer transformer;
  final _formKey = GlobalKey<FormState>();

  final _dirtyController = ValueNotifier<bool>(false);

  final Map<String, TypeProperty> properties = HashMap();

  ValueNotifier<bool> get isDirty => _dirtyController;
  int dirtyWidgets = 0;
  final bool twoWay;

  // constructor

  /// Create a new [FormMapper]
  /// [instance] the source instance whose fields will be bound
  /// [twoWay] if [true], modifications will immediately modify the instance
  FormMapper({required this.instance, this.twoWay=false}) {
    transformer = Transformer(operations);
    type = TypeDescriptor.forType(instance.runtimeType);
  }

  // public

  /// bind a field to a form element
  /// [type] the element type
  /// [path] a field path
  /// [context] the [BuildContext]
  /// [args] any parameters that will be passed to the newly created element
  Widget bind(Type type, {required String path,  required BuildContext context, Map<String, dynamic> args = const {} }) {
    return ValuedWidget.build(type, context: context, mapper: this, path: path, args: args);
  }

  /// return [True] if the form is valid.
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  /// return the [GlobalKey] of the form.
  GlobalKey<FormState> getKey() {
    return _formKey;
  }

  TypeProperty computeProperty(TypeDescriptor typeDescriptor, String path) {
    TypeProperty? result = properties[path];
    TypeProperty? parent;

    if ( result == null) {
      String attribute = path;
      var lastDot = path.lastIndexOf(".");

      if (lastDot >= 0) {
        var parentPath = path.substring(0, lastDot);

        parent = computeProperty(typeDescriptor, parentPath);

        typeDescriptor = (parent.field.type as ObjectType).typeDescriptor;

        attribute = path.substring(lastDot + 1);
      } // if

      var field = typeDescriptor.getField(attribute);

      result = TypeProperty(field: field, path: path, parent: parent, twoWay: twoWay);

      properties[path] = result;
    } // if

    return result;
  }

  /// commit all pending changes to the instance and return it
  dynamic commit() {
    ValuedWidgetContext context = ValuedWidgetContext(mapper: this);
    for ( Operation operation in operations)
      (operation.source as TypeProperty).commit(context);

    return instance;
  }

  void addDirty(int delta) {
    var wasDirty = dirtyWidgets > 0;

    dirtyWidgets += delta;

    var isDirty = dirtyWidgets > 0;

    if ( wasDirty != isDirty)
      markDirty(dirtyWidgets > 0);
  }

  void markDirty(bool dirty) {
    _dirtyController.value = dirty;
  }

  void dispose() {
    for ( Operation operation in operations)
      (operation.target as WidgetProperty).dispose();
  }

  void map({required TypeProperty typeProperty, required String path, required Widget widget, required ValuedWidgetAdapter adapter, DisplayValue<dynamic,dynamic> displayValue=identity, DisplayValue<dynamic,dynamic> parseValue=identity}) {
    var operation = findOperation(path);
    if (operation == null) {
      operations.add(Operation(
          typeProperty,
          WidgetProperty(widget: widget, adapter: adapter, displayValue: displayValue, parseValue: parseValue)
      ));
    }
    else {
      // just replace

      (operation.target as WidgetProperty).widget = widget;
      (operation.target as WidgetProperty).adapter = adapter;
    }
  }

  Operation? findOperation(String path) {
    for ( Operation operation in operations) {
      if ( (operation.source as TypeProperty).path == path)
        return operation;
    }

    return null;
  }

  TypeProperty findProperty(String path) {
    for ( Operation operation in operations)
      if ( (operation.source as TypeProperty).path == path)
        return operation.source as TypeProperty;

    throw Exception("unknown property $path");
  }

  void notifyChange({required String path, required dynamic value}) {
    var property = findProperty(path);

    property.set(instance, value, ValuedWidgetContext(mapper: this));
  }

  /// set the instance that will provide values
  /// [value] an instance
  void setValue(dynamic object) {
    ValuedWidgetContext context = ValuedWidgetContext(mapper: this);

    transformer.transformTarget(object, null, context);
  }
}