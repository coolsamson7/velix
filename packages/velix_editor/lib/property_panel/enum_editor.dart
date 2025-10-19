import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../../commands/command_stack.dart';
import '../../util/message_bus.dart';
import '../metadata/metadata.dart';
import '../metadata/widget_data.dart';
import 'editor_builder.dart';


@Injectable(factory: false)
abstract class AbstractEnumBuilder<T extends Enum> extends PropertyEditorBuilder<T> {
  // instance data

  final List<T> values;

  // constructor

  AbstractEnumBuilder({this.values = const []});

  // override

  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required WidgetData widget,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return _EnumEditor<T>(
      values: values,
      value: value ?? property.defaultValue,
      onChanged: onChanged,
    );
  }
}

class _EnumEditor<T extends Enum> extends StatefulWidget {
  // instance data

  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;

  // constructor

  const _EnumEditor({
    Key? key,
    required this.values,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  // override

  @override
  State<_EnumEditor> createState() => _EnumEditorState<T>();
}

class _EnumEditorState<T extends Enum> extends State<_EnumEditor> {
  // instance data

  late T _selected;

  // internal

  String labelOf(T value) {
    return "editor:enums.${value.runtimeType.toString()}.${value.name}.label".tr();
    //return value.toString();
  }

  // override

  @override
  void initState() {
    super.initState();

    _selected = widget.value as dynamic;
  }

  @override
  void didUpdateWidget(covariant _EnumEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _selected) {
      setState(() => _selected = widget.value as dynamic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButton<T>(
          value: _selected,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(color: Colors.black),
          items: widget.values.map((value) => DropdownMenuItem<T>(
              value: value as T,
              child: Text(labelOf(value)),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selected = value);
              widget.onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
