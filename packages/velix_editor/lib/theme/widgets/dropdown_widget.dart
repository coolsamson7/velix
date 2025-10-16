import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../event/events.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widgets/dropdown.dart';
import '../../metadata/widgets/for.dart';

import '../../util/message_bus.dart';
import '../widget_builder.dart';
import 'for_widget.dart';

@Injectable()
class DropDownWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  final TypeRegistry typeRegistry;

  DropDownWidgetBuilder({required this.typeRegistry}) : super(name: "dropdown");

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    return _DropDownWidget(
      data: data,
      typeRegistry: typeRegistry,
      environment: environment,
    );
  }
}

class _DropDownWidget extends StatefulWidget {
  final DropDownWidgetData data;
  final TypeRegistry typeRegistry;
  final Environment environment;

  const _DropDownWidget({
    required this.data,
    required this.typeRegistry,
    required this.environment,
  });

  @override
  State<_DropDownWidget> createState() => _DropDownWidgetState();
}

class _DropDownWidgetState extends State<_DropDownWidget> {
  dynamic _selectedValue;

  List<DropdownMenuItem<dynamic>> _buildItems(BuildContext context) {
    final items = <DropdownMenuItem<dynamic>>[];

    List<Widget> children = [];

    for (var childData in widget.data.children) {
      if (childData is ForWidgetData) {
        for (var (instance, item) in expandForWidget(context, childData, widget.typeRegistry, widget.environment)) {
          items.add(DropdownMenuItem(
            value: instance,
            child: item,
          ));
        }
      } else {
        // Static widget
        items.add(DropdownMenuItem(
          value: childData,
          child: DynamicWidget(
            model: childData,
            meta: widget.typeRegistry[childData.type],
          ),
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<dynamic>(
      value: _selectedValue,
      hint: const Text('Select'),
      items: _buildItems(context),
      onChanged: (value) {
        setState(() {
          _selectedValue = value;
        });

        widget.environment.get<MessageBus>().publish(
          "selection",
          SelectionEvent(selection: value, source: this),
        );
      },
    );
  }
}



@Injectable()
class DropDownEditWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  final TypeRegistry typeRegistry;

  DropDownEditWidgetBuilder({required this.typeRegistry}) : super(name: "dropdown", edit: true);

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    final items = <Widget>[];

    for (var childData in data.children) {
        items.add(EditWidget(model: childData));
      }

    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          //value: null,
          //hint: const Text('Select an item'), // TODO
          children: items,
          //onChanged: (_) {},
        ),
      ),
    );
  }
}
