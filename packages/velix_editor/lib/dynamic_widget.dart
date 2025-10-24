import 'package:flutter/material.dart';
import 'package:velix_editor/theme/abstract_widget.dart';
import 'package:velix_ui/provider/environment_provider.dart';

import 'metadata/metadata.dart';
import 'metadata/widget_data.dart';

import 'theme/widget_factory.dart';

/// An [DynamicWidget] displays a [WidgetData] in runtime mode.
class DynamicWidget extends StatefulWidget {
  // instance data

  final WidgetData model;
  final WidgetDescriptor meta;
  // constructor

  const DynamicWidget({
    super.key,
    required this.model,
    required this.meta
  });

  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends AbstractEditorWidgetState<DynamicWidget> {
  // instance data

  WidgetFactory? theme;

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    theme ??= EnvironmentProvider.of(context).get<WidgetFactory>();
  }

  @override
  Widget build(BuildContext context) {
    widget.model.widget = this;

    return theme!.builder(widget.model.type).create(widget.model, EnvironmentProvider.of(context), context);
  }
}