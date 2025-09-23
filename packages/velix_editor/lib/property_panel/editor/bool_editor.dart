import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';


import '../../commands/command_stack.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class BooleanEditorBuilder extends PropertyEditorBuilder<bool> {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Switch(
          value: value ?? false,
          onChanged: (newValue) => onChanged(newValue),
        ),
      ],
    );
  }
}
