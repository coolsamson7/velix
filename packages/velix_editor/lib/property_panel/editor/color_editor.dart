import 'package:flutter/material.dart';

import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../components/color_picker.dart';
import '../../metadata/metadata.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class ColorEditorBuilder extends PropertyEditorBuilder<Color> {
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
    return _ColorEditor(
      value: value ?? Colors.white, // TODO
      onChanged: onChanged,
    );
  }
}

class _ColorEditor extends StatefulWidget {
  final Color value;
  final ValueChanged<Color> onChanged;

  const _ColorEditor({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_ColorEditor> createState() => _ColorEditorState();
}

class _ColorEditorState extends State<_ColorEditor> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.value;
  }

  @override
  void didUpdateWidget(covariant _ColorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _selectedColor) {
      setState(() => _selectedColor = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColorInputField(
        value: _selectedColor,
        onChanged: (color) {
          setState(() {
              _selectedColor = color;
              widget.onChanged(_selectedColor);
        });
        }
    );
  }
}
