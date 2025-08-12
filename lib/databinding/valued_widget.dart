
import 'package:flutter/cupertino.dart';

import 'form_mapper.dart';
import 'text_adapter.dart';
import '../mapper/transformer.dart';

/// decorates widget adapters
class WidgetAdapter {
  const WidgetAdapter();
}

dynamic identity(dynamic value) => value;

class WidgetProperty extends Property<ValuedWidgetContext> {
  // instance data

  ValuedWidgetAdapter adapter;
  Widget widget;
  Map<String, dynamic> args = {};
  DisplayValue<dynamic,dynamic> displayValue;
  ParseValue<dynamic,dynamic> parseValue;

  // constructor

  WidgetProperty({required this.widget, required this.adapter, this.displayValue = identity, this.parseValue=identity});

  // public

  T getArg<T>(String key) {
    return args[key] as T;
  }

  void dispose() {
    adapter.dispose(this);
  }

  // implement

  @override
  dynamic get(dynamic instance, ValuedWidgetContext context) {
    return parseValue(adapter.getValue(widget));
  }

  @override
  void set(dynamic instance, dynamic value, ValuedWidgetContext context) {
    return adapter.setValue(widget, displayValue(value), context);
  }
}

/// base class for widget adapters
/// [T] the widget type
abstract class ValuedWidgetAdapter<T> {
  /// return the element type
  Type getType();

  /// return the current value given a widget
  /// [widget] the widget
  dynamic getValue(T widget);

  /// set a current value
  /// [widget] the widget
  /// [value] the value
  /// [context] the [ValuedWidgetContext]
  void setValue(T widget, dynamic value, ValuedWidgetContext context);

  /// dispose any resources
  void dispose(WidgetProperty property);

  /// build and bind the corresponding widget
  /// [context] a [FormMapper]
  /// [mapper] the [FormMapper]
  /// [path] a field path
  /// [args] and parameters that will be handled by the adapter
  T build({required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}});
}

/// base class for widget adapters
/// [T] the widget type
abstract class AbstractValuedWidgetAdapter<T> extends ValuedWidgetAdapter<T> {
  // instance data

  late Type type;

  // constructor

  AbstractValuedWidgetAdapter() {
    type = T;
  }

  // override

  @override
  Type getType() {
    return type;
  }

  @override
  void dispose(WidgetProperty property) {}
}

class ValuedWidgetContext {
  FormMapper? mapper;

  ValuedWidgetContext({required this.mapper});
}

/// A registry for [ValuedWidgetAdapter]s
class ValuedWidget {
  // properties

  static final Map<Type, ValuedWidgetAdapter> _adapters = {};

  // administration

  static void register(ValuedWidgetAdapter adapter) {
    _adapters[adapter.getType()] = adapter;
  }

  static ValuedWidgetAdapter getAdapter(Type type) {
    ValuedWidgetAdapter? adapter =  _adapters[type];
    if (adapter == null)
      throw Exception("ouch");

    return adapter;
  }

  // public

  static Widget build(Type type, {required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}}) {
    return getAdapter(type).build(context: context, mapper: mapper, path: path, args: args);
  }
}