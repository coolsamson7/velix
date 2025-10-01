import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../components/font_picker.dart';
import '../../metadata/metadata.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class FontEditorBuilder extends PropertyEditorBuilder<FontWeight> {
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
    return _FontEditor(
      value: value ?? FontWeight.normal,
      onChanged: onChanged,
    );
  }
}

class _FontEditor extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FontEditor({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_FontEditor> createState() => _FontEditorState();
}

class _FontEditorState extends State<_FontEditor> {
  late String _selectedFont;

  static const List<String> _fonts = ['Roboto', 'Arial', 'Georgia'];

  @override
  void initState() {
    super.initState();
    _selectedFont = widget.value;
  }

  @override
  void didUpdateWidget(covariant _FontEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _selectedFont) {
      setState(() => _selectedFont = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FontPickerDropdown(
        selectedFont: _selectedFont,
        availableFonts: _fonts,
        onFontSelected: (font) {
          setState(() {
              _selectedFont = font!;
              widget.onChanged(_selectedFont);
        });
        }
    );
  }
}
