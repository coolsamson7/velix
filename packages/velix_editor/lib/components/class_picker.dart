import 'package:flutter/material.dart';

import '../actions/types.dart';

class ClassPickerDialog extends StatefulWidget {
  final ClassRegistry registry;

  const ClassPickerDialog({required this.registry, super.key});

  @override
  State<ClassPickerDialog> createState() => _ClassPickerDialogState();
}

class _ClassPickerDialogState extends State<ClassPickerDialog> {
  ClassDesc? _selected;

  @override
  Widget build(BuildContext context) {
    final classes = widget.registry.classes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      title: const Text("Select Class"),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          children: [
            DropdownButton<ClassDesc>(
              isExpanded: true,
              hint: const Text("Choose a class"),
              value: _selected,
              items: classes.map((cls) {
                return DropdownMenuItem(
                  value: cls,
                  child: Text(cls.name),
                );
              }).toList(),
              onChanged: (cls) => setState(() => _selected = cls),
            ),
            const SizedBox(height: 16),
            if (_selected != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SuperClass: ${_selected!.superClass?.name ?? '-'}"),
                      const SizedBox(height: 8),
                      Text("Properties:"),
                      for (var prop in _selected!.properties.values)
                        Text(" • ${prop.name}: ${prop.type.name}"),
                      const SizedBox(height: 8),
                      Text("Methods:"),
                      for (var prop in _selected!.properties.values.where((p) => p.isMethod()))
                        Text(" • ${prop.name}(${(prop as MethodDesc).parameters.map((p) => p.name).join(', ')}): ${prop.type.name}"),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel")),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text("Select")),
      ],
    );
  }
}


class ClassSelector extends StatefulWidget {
  final ClassRegistry registry;
  final ClassDesc? initial;
  final ValueChanged<ClassDesc?>? onChanged;

  const ClassSelector({
    super.key,
    required this.registry,
    this.initial,
    this.onChanged,
  });

  @override
  State<ClassSelector> createState() => _ClassSelectorState();
}

class _ClassSelectorState extends State<ClassSelector> {
  ClassDesc? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  Future<void> _pickClass() async {
    final selected = await showDialog<ClassDesc>(
      context: context,
      builder: (_) => ClassPickerDialog(registry: widget.registry),
    );

    if (selected != null) {
      setState(() => _selected = selected);
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickClass,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                _selected?.name ?? "Select a class...",
                style: TextStyle(
                  color: _selected != null ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
