import 'package:flutter/material.dart' hide MetaData;

import './dynamic_widget.dart';
import './metadata/type_registry.dart';
import './metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';

class WidgetContainer extends StatefulWidget {
  // instance data

  final List<WidgetData> models;
  final TypeRegistry typeRegistry;

  // constructor

  const WidgetContainer({super.key, required this.models, required this.typeRegistry});

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

    return Container(
      color: Colors.grey.shade200,
      child: ListView(
        children: widget.models.map((m) => DynamicWidget(model: m, meta: typeRegistry![m.type])).toList(),
      ),
    );
  }
}