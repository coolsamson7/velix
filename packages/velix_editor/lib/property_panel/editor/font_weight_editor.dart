import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class FontWeightEditorBuilder extends PropertyEditorBuilder<FontWeight> {
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
    return _FontWeightEditorStateful(
      value: value ?? FontWeight.normal,
      onChanged: onChanged,
    );
  }
}

class _FontWeightEditorStateful extends StatefulWidget {
  // instance data

  final FontWeight value;
  final ValueChanged<dynamic> onChanged;

  // constructor

  const _FontWeightEditorStateful({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_FontWeightEditorStateful> createState() =>
      _FontWeightEditorStatefulState();
}

class _FontWeightEditorStatefulState extends State<_FontWeightEditorStateful> {
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
  void didUpdateWidget(covariant _FontWeightEditorStateful oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _selectedWeight) {
      setState(() {
        _selectedWeight = widget.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        DropdownButton<FontWeight>(
          value: _selectedWeight,
          items: _weights.entries
              .map(
                (e) => DropdownMenuItem<FontWeight>(
              value: e.value,
              child: Text(e.key),
            ),
          )
              .toList(),
          onChanged: (weight) {
            if (weight != null) {
              setState(() {
                _selectedWeight = weight;
              });
              widget.onChanged(weight);
            }
          },
        ),
      ],
    );
  }
}
