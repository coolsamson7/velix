import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/util/collections.dart';

import 'form_mapper.dart';
import 'package:velix/util/transformer.dart';

/// decorates widget adapters
class WidgetAdapter {
  // instance data

  final List<TargetPlatform> platforms;

  // constructor

  const WidgetAdapter({required this.platforms});
}

/// base class for [States] that display [WidgetData]
abstract class AbstractWidgetState<T extends StatefulWidget> extends State<T> {
   String extractId(Object widget) {
       return (this.widget.key as ValueKey<String>).value; // hmm....
   }
}

dynamic identity(dynamic value) => value;

class WidgetProperty extends Property<ValuedWidgetContext> {
  // instance data

  ValuedWidgetAdapter adapter;
  Object widget;
  Map<String, dynamic> args = {};
  DisplayValue<dynamic,dynamic> displayValue;
  ParseValue<dynamic,dynamic> parseValue;

  // constructor

  WidgetProperty({required this.widget, required this.adapter, this.displayValue = identity, this.parseValue=identity});

  // public

  T arg<T>(String key) {
    return args[key] as T;
  }

  void setArg<T>(String key, T value) {
    args[key] = value;
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

  List<TargetPlatform> supportedPlatforms();

  bool supports(TargetPlatform platform);

  String getId(T widget);

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
  /// [property] a [TypeProperty]
  /// [args] and parameters that will be handled by the adapter
  Widget build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args});
}

/// base class for widget adapters
/// [T] the widget type
abstract class AbstractValuedWidgetAdapter<T> extends ValuedWidgetAdapter<T> {
  // instance data

  final String name;
  late WidgetAdapter annotation;
  List<TargetPlatform> platforms;

  // constructor

  AbstractValuedWidgetAdapter(this.name, this.platforms) {
    annotation = TypeDescriptor.forType(runtimeType).getAnnotation<WidgetAdapter>()!;

    ValuedWidget.register(this);
  }

  // override

  @override
  String getId(T widget) {
    if (widget is Widget)
      return (widget.key as ValueKey<String>).value;

    if ( widget is AbstractWidgetState)
      return widget.extractId(widget);

    throw Exception("ouch");
  }

  @override
  List<TargetPlatform> supportedPlatforms() {
    return platforms;
  }

  @override
  bool supports(TargetPlatform platform) {
    return platforms.contains(platform);
  }

  @override
  Type getType() {
    return T;
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

typedef AdapterKey = (TargetPlatform, String);

/// A registry for [ValuedWidgetAdapter]s
class ValuedWidget {
  // properties

  static final Map<AdapterKey, ValuedWidgetAdapter> _adapters = {};

  static TargetPlatform platform = defaultTargetPlatform;

  // administration

  static void register(ValuedWidgetAdapter adapter) {
     for (var platform in adapter.supportedPlatforms())
      _adapters[(platform, adapter.getName())] = adapter;
  }


  static ValuedWidgetAdapter getAdapter(String name) {
    ValuedWidgetAdapter? result = _adapters[(platform, name)];

    if (result == null)
      throw Exception("missing adapter for type $name");

    return result;
  }

  // public

  static Widget build<T>(String name, {required BuildContext context, required FormMapper mapper, required String path, Keywords? args}) {
    var property = mapper.computeProperty(mapper.type, path);

    return getAdapter(name).build(context: context, mapper: mapper, property: property, args: args ?? Keywords.empty);
  }
}