import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../metadata/widgets/grid.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';


@Injectable()
class RowConfigEditor extends PropertyEditorBuilder<GridRow> {
  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required dynamic object,
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    final row = value as GridRow;

    return Row(
      children: [
        const Text("Height:"),
        const SizedBox(width: 4),
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: row.size.toString() ?? "",
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6)),
            onChanged: (v) {
              row.size = double.tryParse(v)!;
              onChanged(row);
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text("Align:"),
        const SizedBox(width: 4),
        DropdownButton<GridAlignment>(
          value: row.alignment,
          items: GridAlignment.values
              .map((a) => DropdownMenuItem(
            value: a,
            child: Text(a.name),
          ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            row.alignment = v;
            onChanged(row);
          },
        ),
      ],
    );
  }
}
