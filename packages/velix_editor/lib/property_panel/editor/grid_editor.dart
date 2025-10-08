import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';
import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../metadata/widgets/grid.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class GridItemEditor extends PropertyEditorBuilder<GridItem> {
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
    final row = value as GridItem;
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            color: isHovered ? Colors.grey.shade200 : Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Height input
                const Text("Height:", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: row.size.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) {
                      row.size = double.tryParse(v) ?? row.size;
                      onChanged(row);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Mode selector
                const Text("Mode:", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Row(
                  children: GridSizeMode.values.map((mode) {
                    final selectedColor =
                    row.sizeMode == mode ? Colors.blue.shade700 : Colors.grey.shade400;
                    return GestureDetector(
                      onTap: () {
                        row.sizeMode = mode;
                        onChanged(row);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mode.name,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),

                // Alignment icons
                const Text("Align:", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Row(
                  children: GridAlignment.values.map((alignment) {
                    final bool selected = row.alignment == alignment;
                    return GestureDetector(
                      onTap: () {
                        row.alignment = alignment;
                        onChanged(row);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selected ? Colors.blue.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _iconFor(alignment),
                          size: 16,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(GridAlignment alignment) {
    switch (alignment) {
      case GridAlignment.start:
        return Icons.vertical_align_top;
      case GridAlignment.center:
        return Icons.vertical_align_center;
      case GridAlignment.end:
        return Icons.vertical_align_bottom;
      case GridAlignment.stretch:
        return Icons.height;
      default:
        return Icons.help_outline;
    }
  }
}
