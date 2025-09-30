import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../metadata/properties/properties.dart' hide Border;
import '../../util/message_bus.dart';
import '../editor_builder.dart';

class ValueField extends StatefulWidget {
  final Value value;
  final ValueChanged<dynamic> onChanged;

  const ValueField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  // override

  @override
  State<ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<ValueField> {
  late ValueType _mode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _mode = widget.value.type;
    _controller = TextEditingController(text: widget.value.value);
  }

  Widget _buildEditor() {
    switch (_mode) {
      case ValueType.i18n:
        return _I18nEditor(controller: _controller);
      case ValueType.binding:
        return _BindingEditor(controller: _controller);
      case ValueType.value:
        return _ValueEditor(controller: _controller);
    }
  }

  IconData _modeIcon(ValueType mode) {
    switch (mode) {
      case ValueType.i18n:
        return Icons.language; // 🌐
      case ValueType.binding:
        return Icons.link; // 🔗
      case ValueType.value:
        return Icons.edit; // ✏️
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildEditor()),
        const SizedBox(width: 4),
        DropdownButton<ValueType>(
          value: _mode,
          underline: const SizedBox(),
          icon: Icon(_modeIcon(_mode)),
          items: ValueType.values.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Icon(_modeIcon(mode)),
            );
          }).toList(),
          onChanged: (mode) {
            if (mode != null) {
              setState(() => _mode = mode);
            }
          },
        ),
      ],
    );
  }
}

//
// Example editor widgets (all text fields but with different wrappers/logics)
//
class _I18nEditor extends StatelessWidget {
  final TextEditingController controller;
  const _I18nEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'I18n key',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _BindingEditor extends StatelessWidget {
  final TextEditingController controller;
  const _BindingEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter binding (e.g. model.name)',
        ),
      ),
    );
  }
}

class _ValueEditor extends StatelessWidget {
  final TextEditingController controller;
  const _ValueEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Value',
        border: OutlineInputBorder(),
      ),
    );
  }
}

@Injectable()
class ValueEditorBuilder extends PropertyEditorBuilder<Value> {
  // override

  @override
  Widget buildEditor({
    required MessageBus messageBus,
    required CommandStack commandStack,
    required FieldDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return ValueField(
      value: value,
      onChanged: onChanged,
    );
  }
}
