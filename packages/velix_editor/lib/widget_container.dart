import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_ui/databinding/form_mapper.dart';

import './dynamic_widget.dart';
import './metadata/type_registry.dart';
import './metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';

class WidgetContext {
  // instance data

  dynamic instance;
  TypeDescriptor typeDescriptor;
  FormMapper formMapper;
  late WidgetContainer container;
  Map<TypeProperty,Set<WidgetData>> bindings = {};

  // constructor

  WidgetContext({required this.instance, FormMapper? mapper}) : typeDescriptor = TypeDescriptor.forType(instance.runtimeType),   formMapper = mapper ?? FormMapper(instance: instance, twoWay: true) {
    //formMapper.addListener((event) => onEvent, emitOnChange: true);
  }

  //( callback

  void onEvent(FormEvent event) {
    var widgets = bindings[event.path]; // TODO FOO
    if (widgets != null) {
      for ( var widget in widgets)
        widget.update();
    }
  }

  // public

   void addBinding(TypeProperty binding, WidgetData widget) {
     var widgets = bindings[binding];
     if (widgets == null) {
       bindings[binding] = widgets = HashSet<WidgetData>();
     }

     widgets.add(widget);
   }
}

class WidgetContextScope extends InheritedWidget {
  final WidgetContext contextValue;

  const WidgetContextScope({
    super.key,
    required this.contextValue,
    required super.child,
  });

  static WidgetContext of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WidgetContextScope>();
    return scope?.contextValue ??
        (throw FlutterError('No WidgetContextScope found in context'));
  }

  @override
  bool updateShouldNotify(WidgetContextScope old) =>
      contextValue != old.contextValue;
}

class WidgetContainer extends StatefulWidget {
  // instance data

  late final List<WidgetData> models;
  final WidgetContext context;

  // constructor

  WidgetContainer({super.key, required dynamic instance, required WidgetData widget,  FormMapper? mapper})
    :
        context = WidgetContext(instance: instance, mapper: mapper),
        models = [widget] {
    context.container = this;
  }

  // override

  @override
  State<WidgetContainer> createState() => _WidgetContainerState();
}

class _WidgetContainerState extends State<WidgetContainer> {
  // instance data

  TypeRegistry? typeRegistry;
  StreamSubscription? subscription;

  // override

  @override
  void dispose() {
    super.dispose();

    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    typeRegistry ??= EnvironmentProvider.of(context).get<TypeRegistry>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.context.formMapper.setValue(widget.context.instance);

      subscription ??= widget.context.formMapper.addListener((event) {
          for ( var widget in widget.context.bindings[event.property] ?? {})
            widget.update();

        }, emitOnChange: true);
    });

    //return Provider<WidgetContext>.value(
    return WidgetContextScope(contextValue: widget.context,
        //value: widget.context,
        child: Container(
          color: Colors.grey.shade200,
          child: ListView(
            children: widget.models.map((m) => DynamicWidget(model: m, meta: typeRegistry![m.type])).toList(),
          ),
    ));
  }
}