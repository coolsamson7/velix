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

  // constructor

  WidgetContext({required this.page}) :  formMapper = FormMapper(instance: page, twoWay: true);
}

class WidgetContainer extends StatefulWidget {
  // instance data

  final List<WidgetData> models;
  final TypeRegistry typeRegistry;
  final WidgetContext context;

  // constructor

  WidgetContainer({super.key, required this.models, required this.typeRegistry, required this.context}) {
    //formMapper = FormMapper(instance: context.page, twoWay: false);
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