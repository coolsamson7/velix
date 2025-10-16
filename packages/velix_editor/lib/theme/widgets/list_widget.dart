import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/type_registry.dart';

import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../metadata/widgets/for.dart';
import '../../metadata/widgets/list.dart';
import '../widget_builder.dart';
import 'for_widget.dart';

@Injectable()
class ListWidgetBuilder extends WidgetBuilder<ListWidgetData> {
  final TypeRegistry typeRegistry;

  ListWidgetBuilder({required this.typeRegistry}) : super(name: "list");

  @override
  Widget create(ListWidgetData data, Environment environment, BuildContext context) {
    return _ListWidget(
      data: data,
      typeRegistry: typeRegistry,
      environment: environment,
    );
  }
}

class _ListWidget extends StatefulWidget {
  final ListWidgetData data;
  final TypeRegistry typeRegistry;
  final Environment environment;

  const _ListWidget({
    required this.data,
    required this.typeRegistry,
    required this.environment,
    super.key,
  });

  @override
  State<_ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<_ListWidget> {
  List<Widget> _buildChildren() {
    final children = <Widget>[];

    for (var childData in widget.data.children) {
      if (childData is ForWidgetData) {
        for (var (instance, widget) in childData.expand(context, widget.typeRegistry, widget.environment))
          children.add(widget);
      }
      else {
        children.add(DynamicWidget(
          model: childData,
          meta: widget.typeRegistry[childData.type],
        ));
      }
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _buildChildren(),
    );
  }
}

@Injectable()
class EditListWidgetBuilder extends WidgetBuilder<ListWidgetData> {
  TypeRegistry typeRegistry;

  EditListWidgetBuilder({required this.typeRegistry}) : super(name: "list", edit: true);

  @override
  Widget create(ListWidgetData data, Environment environment, BuildContext context) {
    return _EditListWidget(
      data: data,
      typeRegistry: typeRegistry,
      environment: environment,
    );
  }
}

class _EditListWidget extends StatelessWidget {
  final ListWidgetData data;
  final Environment environment;
  final TypeRegistry typeRegistry;

  const _EditListWidget({required this.data, required this.environment, required this.typeRegistry, super.key});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var childData in data.children) {
        children.add(EditWidget(model: childData));
      }

    return SizedBox(
      height: 100, // adjust placeholder height
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

