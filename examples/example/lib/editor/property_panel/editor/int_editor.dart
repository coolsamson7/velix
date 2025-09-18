import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../editor_builder.dart';

@Injectable()
class IntEditorBuilder extends PropertyEditorBuilder<int> {
  // override

  @override
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? "0"),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) {
        final intValue = int.tryParse(val) ?? 0;
        onChanged(intValue);
      },
    );
  }
}
