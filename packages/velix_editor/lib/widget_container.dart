import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velix_ui/databinding/form_mapper.dart';

import './dynamic_widget.dart';
import './metadata/type_registry.dart';
import './metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';

class WidgetContext {
  // instance data

  dynamic instance;
  FormMapper formMapper;
  late WidgetContainer container;
  Map<TypeProperty,Set<WidgetData>> bindings = {};

  // constructor

  WidgetContext({required this.instance}) :  formMapper = FormMapper(instance: instance, twoWay: true) {
    //formMapper.addListener((event) => onEvent, emitOnChange: true);
  }

  //( callback

  void onEvent(FormEvent event) {
    var widgets = bindings[event.path];
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

class WidgetContainer extends StatefulWidget {
  // instance data

  final List<WidgetData> models;
  final TypeRegistry typeRegistry;
  final WidgetContext context;

  // constructor

  WidgetContainer({super.key, required this.models, required this.typeRegistry, required this.context}) {
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

    return Provider<WidgetContext>.value(
        value: widget.context,
        child: Container(
          color: Colors.grey.shade200,
          child: ListView(
            children: widget.models.map((m) => DynamicWidget(model: m, meta: typeRegistry![m.type])).toList(),
          ),
    ));
  }
}