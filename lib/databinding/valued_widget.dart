
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:velix/util/collections.dart';

import 'form_mapper.dart';
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

  T arg<T>(String key) {
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

  /// return the platform name
  String getPlatform();

  /// return the element name
  String getName();

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
  Widget build({required BuildContext context, required FormMapper mapper, required String path, required Keywords args});
}

/// base class for widget adapters
/// [T] the widget type
abstract class AbstractValuedWidgetAdapter<T> extends ValuedWidgetAdapter<T> {
  // instance data

  final String name;
  final Type type;
  final String platform;

  // constructor

  AbstractValuedWidgetAdapter(this.name, this.platform) : type = T {
    ValuedWidget.register(this);
  }

  // override

  @override
  Type getType() {
    return type;
  }

  @override
  String getPlatform() {
    return platform;
  }

  @override
  String getName() {
    return name;
  }

  @override
  void dispose(WidgetProperty property) {}
}

class ValuedWidgetContext {
  FormMapper? mapper;

  ValuedWidgetContext({required this.mapper});
}

typedef Key = (String, String);

/// A registry for [ValuedWidgetAdapter]s
class ValuedWidget {
  // properties

  static final Map<Key, ValuedWidgetAdapter> _adapters = {};

  static String platform = "iOS";

  // administration

  static void register(ValuedWidgetAdapter adapter) {
     _adapters[(platform, adapter.getName())] = adapter;
  }

  static ValuedWidgetAdapter getAdapter(String name) {
    ValuedWidgetAdapter? result = _adapters[(platform, name)] ?? _adapters[("", name)];

    if (result == null)
      throw Exception("missing adapter for type $name");

    return result;
  }

  // public

  static Widget build<T>(String name, {required BuildContext context, required FormMapper mapper, required String path, Keywords? args}) {
    return getAdapter(name).build(context: context, mapper: mapper, path: path, args: args ?? Keywords.empty);
  }
}