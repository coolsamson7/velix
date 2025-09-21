import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../editor_builder.dart';

@Injectable()
class FontStyleEditorBuilder extends PropertyEditorBuilder<FontStyle> {
  // override

  @override
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return _FontStyleEditorStateful(
      value: value ?? FontStyle.normal,
      onChanged: onChanged,
    );
  }
}

class _FontStyleEditorStateful extends StatefulWidget {
  // instance data

  final FontStyle value;
  final ValueChanged<dynamic> onChanged;

  // constructor

  const _FontStyleEditorStateful({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_FontStyleEditorStateful> createState() =>
      _FontStyleEditorStatefulState();
}

class _FontStyleEditorStatefulState extends State<_FontStyleEditorStateful> {
  late FontStyle _selectedStyle;

  final List<FontStyle> _styles = [
    FontStyle.normal,
    FontStyle.italic
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.value;
  }

  @override
  void didUpdateWidget(covariant _FontStyleEditorStateful oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _selectedStyle) {
      setState(() {
        _selectedStyle = widget.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ToggleButtons(
          isSelected: _styles.map((s) => s == _selectedStyle).toList(),
          onPressed: (index) {
            final style = _styles[index];
            setState(() {
              _selectedStyle = style;
            });
            widget.onChanged(style);
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Regular'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Italic'),
            ),
          ],
        ),
      ],
    );
  }
}
