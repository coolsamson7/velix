import 'package:flutter/material.dart' hide Theme, MetaData;
import 'package:sample/editor/metadata/metadata.dart';
import 'package:sample/editor/provider/environment_provider.dart';
import 'package:sample/editor/theme/theme.dart';
import 'metadata/widget_data.dart';


class DynamicWidget extends StatefulWidget {
  // instance data

  final WidgetData model;
  final MetaData meta;
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

  late final Theme theme;

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    theme = EnvironmentProvider.of(context).get<Theme>();
  }

  @override
  Widget build(BuildContext context) {
    return theme.builder(widget.model.type).create(widget.model);
  }
}