
import 'package:flutter/cupertino.dart';
import 'package:flutter_application/databinding/form_mapper.dart';
import 'package:flutter_application/databinding/text_adapter.dart';
import 'package:flutter_application/mapper/transformer.dart';

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

abstract class ValuedWidgetAdapter<T> {
  Type getType();
  dynamic getValue(T widget);
  void setValue(T widget, dynamic value, ValuedWidgetContext context);
  void dispose(WidgetProperty property);

  T build({required BuildContext context, required FormMapper mapper, required String path, Map<String, dynamic> args = const {}});
}

abstract class AbstractValuedWidgetAdapter<T> extends ValuedWidgetAdapter<T> {
  Type type;

  AbstractValuedWidgetAdapter({required this.type});

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