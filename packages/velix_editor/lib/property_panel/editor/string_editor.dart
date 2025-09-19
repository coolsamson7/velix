import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../editor_builder.dart';

@Injectable()
class StringEditorBuilder extends PropertyEditorBuilder<String> {
  // override

  @override
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? ""),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}