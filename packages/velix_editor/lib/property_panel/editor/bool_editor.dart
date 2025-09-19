import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../editor_builder.dart';

@Injectable()
class BooleanEditorBuilder extends PropertyEditorBuilder<bool> {
  @override
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Switch(
          value: value ?? false,
          onChanged: (newValue) => onChanged(newValue),
        ),
      ],
    );
  }
}
