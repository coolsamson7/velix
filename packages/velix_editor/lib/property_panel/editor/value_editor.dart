import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';

@Dataclass()
enum ValueType {
  i18n,
  binding,
  value
}

@Dataclass()
class Value {
  ValueType type;
  dynamic value;

  Value({required this.type, required this.value});
}

class MultiEditorField extends StatefulWidget {
  final String initialValue;
  final ValueType initialMode;

  const MultiEditorField({
    super.key,
    this.initialValue = '',
    this.initialMode = ValueType.value,
  });

  @override
  State<MultiEditorField> createState() => _MultiEditorFieldState();
}

class _MultiEditorFieldState extends State<MultiEditorField> {
  late ValueType _mode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _controller = TextEditingController(text: widget.initialValue);
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
