import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../util/message_bus.dart';
import '../metadata/metadata.dart';
import 'editor_builder.dart';


@Injectable(factory: false)
class AbstractEnumBuilder<T> extends PropertyEditorBuilder<T> {
  // override

  @override
  Widget buildEditor({
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return _EnumEditor<T>(
      value: value ?? property.defaultValue,
      onChanged: onChanged,
    );
  }
}

class _EnumEditor<T> extends StatefulWidget {
  // instance data

  final T value;
  final ValueChanged<T> onChanged;

  // constructor

  const _EnumEditor({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  // override

  @override
  State<_EnumEditor> createState() => _EnumEditorState<T>();
}

class _EnumEditorState<T> extends State<_EnumEditor> {
  // instance data

  late T _selected;
  late List<T> _values;

  // internal

  String labelOf(T value) {
    return value.toString();
  }

  // override

  @override
  void initState() {
    super.initState();

    _selected = widget.value;
    _values = TypeDescriptor.forType<T>().enumValues as List<T>;
  }

  @override
  void didUpdateWidget(covariant _EnumEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _selected) {
      setState(() => _selected = widget.value);
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
          items: _values.map((value) => DropdownMenuItem<T>(
              value: value,
              child: Text(labelOf(value)),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selected = value as T);
              widget.onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
