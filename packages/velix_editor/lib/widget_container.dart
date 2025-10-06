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

  dynamic page;
  FormMapper formMapper; // TODO databinding
  late WidgetContainer container;
  Map<TypeProperty,Set<WidgetData>> bindings = {};

  // constructor

  WidgetContext({required this.page}) :  formMapper = FormMapper(instance: page, twoWay: true) {
    //formMapper.addListener((event) => onEvent, emitOnChange: true);
  }

  //( callback

  void onEvent(FormEvent event) {
    var widgets = bindings[event.path];
    if (widgets != null) {
      for ( var widget in widgets)
        widget.widget!.setState((){}); // TODO
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

  // override

  @override
  Widget build(BuildContext context) {
    typeRegistry ??= EnvironmentProvider.of(context).get<TypeRegistry>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.context.formMapper.setValue(widget.context.page);

      widget.context.formMapper.addListener((event) { // TODO. wohgin + dispose
        for ( var w in widget.context.bindings[event.property] ?? {})
          w.update();

      }, emitOnChange: true);

      /* take care of bindings

      var valuedWidgetContext = ValuedWidgetContext(mapper: widget.context.formMapper);
      for ( var typeProperty in widget.context.bindings.keys) {
        var v = typeProperty.get(widget.context.page, valuedWidgetContext);

        print(v);
      }*/
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