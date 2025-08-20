import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:velix/util/collections.dart';
import 'text_adapter.dart';
import 'valued_widget.dart';

import '../reflectable/reflectable.dart';
import '../mapper/transformer.dart';
import '../validation/validation.dart';

class SmartForm extends Form {
  // static methods

  static SmartFormState? of(BuildContext context) =>
      context.findAncestorStateOfType<SmartFormState>();

  // constructor

  SmartForm({super.key, required super.child, super.onWillPop, super.onChanged, AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled});

  // override

  @override
  SmartFormState createState() => SmartFormState();
}

class SmartFormState extends FormState {
  // instance data

  bool _submitted = false;

  bool get submitted => _submitted;

  // override

  @override
  bool validate() {
    _submitted = true;

    final result = super.validate();
    setState(() => {});

    return result;
  }

  @override
  void reset() {
    _submitted = false;
    super.reset();
  }
}

/// @internal
class TypeProperty extends Property<ValuedWidgetContext> {
  // instance data

  final String path;
  final FieldDescriptor? field;

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

  void rollback(ValuedWidgetContext context) {
    if ( isDirty()) {
      set(context.mapper!.instance, initialValue, context);
    }
  }

  void commit(ValuedWidgetContext context) {
    if ( isDirty()) {
      if ( !context.mapper!.twoWay )
        callSetter(context.mapper!.instance, value, context);

      initialValue = value;
      context.mapper!.addDirty(-1);
    }
  }

  // internal

  void validate(dynamic value) {
    field!.type.validate(value);
  }

  Type getType() {
    return field!.type.type;
  }

  bool isInitialized() {
    return initialValue != this;
  }

  bool isDirty() {
    return value != initialValue;
  }

  TypeProperty? findChild(String property) {
    return findElement(children, (child) => child.path == property);
  }

  dynamic newInstance() {
    Map<Symbol, dynamic> args = {};

    // fetch all required values

    var typeDescriptor = (field!.type as ObjectType).typeDescriptor;

    for (var constructorParameter in typeDescriptor.constructorParameters) {
      var name = constructorParameter.name;

      var child = findChild("$path.$name");

      if ( child != null) {
        // take the value from the mapped child widget

        args[Symbol(name)] = child.value;
      }
      else {
        // take it from the original - not mapped - object property

        args[Symbol(name)] = typeDescriptor.get(initialValue, name);
      }
    }

    return Function.apply(typeDescriptor.constructor, [], args);
  }

  void callSetter(dynamic instance, dynamic value, ValuedWidgetContext context) {
    if (parent != null)
      instance = parent!.get(instance, context);

    this.value = value;

    if ( field!.isFinal ) {
        parent!.callSetter(context.mapper!.instance, parent!.newInstance(), context);
    } // if
    else {
      field!.setter!(instance, value);
    }
  }

  // implement

  @override
  dynamic get(dynamic instance, ValuedWidgetContext context) {
    if (!isInitialized()) {
      if (parent != null) {
        instance = parent!.get(instance, context);
      }

      value = initialValue = field!.getter(instance);
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
        callSetter(instance, value, context);
      }

      var newDirty = isDirty();

      if (wasDirty != newDirty)
        context.mapper!.addDirty(wasDirty ? -1 : 1);
    } // if
  }
}

class RootProperty extends TypeProperty {
  // instance data

  FormMapper mapper;

  // constructor

  RootProperty({required this.mapper, super.field, super.path = ""});

  // override

  @override
  dynamic get(dynamic instance, ValuedWidgetContext context) {
    return instance;
  }

  @override
  void set(dynamic instance, dynamic value, ValuedWidgetContext context) {
    this.value = value;

    mapper.instance = value;
}

  @override
  void callSetter(dynamic instance, dynamic value, ValuedWidgetContext context) {
    mapper.instance = value;
  }

  @override
  dynamic newInstance() {
    Map<Symbol, dynamic> args = {};

    // fetch all required values

    var typeDescriptor = mapper.type;

    for (var constructorParameter in typeDescriptor.constructorParameters) {
      var name = constructorParameter.name;

      var child = findChild(name);

      if ( child != null) {
        // take the value from the mapped child widget

        args[Symbol(name)] = child.value;
      }
      else {
        // take it from the original - not mapped - object property

        args[Symbol(name)] = typeDescriptor.get(mapper.instance, name);
      }
    }

    return Function.apply(typeDescriptor.constructor, [], args);
  }
}

/// A [FormMapper] is used to bind field values to form elements
class FormMapper {
  // instance data

  dynamic instance;
  late TypeDescriptor type;
  RootProperty? rootProperty;
  final List<Operation<ValuedWidgetContext>> operations = [];
  final Map<String,Operation<ValuedWidgetContext>> path2Operation = {};
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

    if ( type.isImmutable())
      rootProperty = RootProperty(mapper: this);
  }

  // public

  /// bind a field to a form element
  /// [T] the element type
  /// [path] a field path
  /// [context] the [BuildContext]
  /// [args] any parameters that will be passed to the newly created element
  T bind<T>({required String path,  required BuildContext context, Map<String, dynamic> args = const {} }) {
    return ValuedWidget.build<T>(context: context, mapper: this, path: path, args: args);
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
    TypeProperty? parent = rootProperty;

    if ( result == null) {
      String attribute = path;
      var lastDot = path.lastIndexOf(".");

      if (lastDot >= 0) {
        var parentPath = path.substring(0, lastDot);

        parent = computeProperty(typeDescriptor, parentPath);

        typeDescriptor = (parent.field!.type as ObjectType).typeDescriptor;

        attribute = path.substring(lastDot + 1);
      } // if

      var field = typeDescriptor.getField(attribute);

      result = TypeProperty(field: field, path: path, parent: parent, twoWay: twoWay);

      properties[path] = result;
    } // if

    return result;
  }

  /// commit all pending changes to the instance and return it
  T commit<T>() {
    ValuedWidgetContext context = ValuedWidgetContext(mapper: this);
    for ( Operation operation in operations)
      (operation.source as TypeProperty).commit(context);

    return instance as T;
  }

  /// rollback all changes
  void rollback() {
    ValuedWidgetContext context = ValuedWidgetContext(mapper: this);
    for ( Operation operation in operations)
      (operation.source as TypeProperty).rollback(context);
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

      path2Operation[path] = operations.last;
    }
    else {
      // just replace

      (operation.target as WidgetProperty).widget = widget;
      (operation.target as WidgetProperty).adapter = adapter;
    }
  }

  Operation<ValuedWidgetContext>? findOperation(String path) {
    return path2Operation[path];
  }

  TypeProperty findProperty(String path) {
    return findOperation(path)!.source as TypeProperty;
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