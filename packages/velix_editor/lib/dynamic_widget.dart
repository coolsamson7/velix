import 'package:flutter/material.dart' hide Theme, MetaData;
import 'package:velix_di/di/di.dart';
import 'package:velix_ui/provider/environment_provider.dart';

import 'metadata/metadata.dart';
import 'metadata/widget_data.dart';

import 'theme/theme.dart';


class DynamicWidget extends StatefulWidget {
  // instance data

  final WidgetData model;
  final WidgetDescriptor meta;
  final WidgetData? parent; // optional reference to parent container

  const DynamicWidget({
    super.key,
    required this.model,
    required this.meta,
    this.parent,
  });

  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {
  // instance data

  late final WidgetFactory theme;
  late final Environment environment;

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    theme = environment.get<WidgetFactory>();
  }

  @override
  Widget build(BuildContext context) {
    return theme.builder(widget.model.type).create(widget.model, environment);
  }
}