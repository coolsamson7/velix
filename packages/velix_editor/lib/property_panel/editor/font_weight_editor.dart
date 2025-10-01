import 'package:flutter/material.dart';

import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class FontWeightEditorBuilder extends PropertyEditorBuilder<FontWeight> {
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
    return _FontWeightEditor(
      value: value ?? FontWeight.normal,
      onChanged: onChanged,
    );
  }
}

class _FontWeightEditor extends StatefulWidget {
  final FontWeight value;
  final ValueChanged<FontWeight> onChanged;

  const _FontWeightEditor({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_FontWeightEditor> createState() => _FontWeightEditorState();
}

class _FontWeightEditorState extends State<_FontWeightEditor> {
  late FontWeight _selectedWeight;

  static const Map<String, FontWeight> _weights = {
    'Thin': FontWeight.w100,
    'ExtraLight': FontWeight.w200,
    'Light': FontWeight.w300,
    'Normal': FontWeight.w400,
    'Medium': FontWeight.w500,
    'SemiBold': FontWeight.w600,
    'Bold': FontWeight.w700,
    'ExtraBold': FontWeight.w800,
    'Black': FontWeight.w900,
  };

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.value;
  }

  @override
  void didUpdateWidget(covariant _FontWeightEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _selectedWeight) {
      setState(() => _selectedWeight = widget.value);
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
        child: DropdownButton<FontWeight>(
          value: _selectedWeight,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(color: Colors.black),
          items: _weights.entries
              .map(
                (e) => DropdownMenuItem<FontWeight>(
              value: e.value,
              child: Text(
                e.key,
                style: TextStyle(fontWeight: e.value),
              ),
            ),
          )
              .toList(),
          onChanged: (weight) {
            if (weight != null) {
              setState(() => _selectedWeight = weight);
              widget.onChanged(weight);
            }
          },
        ),
      ),
    );
  }
}
