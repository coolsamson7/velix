import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';
import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../metadata/widget_data.dart';
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
    required WidgetData widget,
    required PropertyDescriptor property,
    required dynamic object,
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    final row = value as GridItem;

    // determines if we are editing columns (horizontal = true)
    final horizontal = property.name == "cols";

    final modeKey = GlobalKey();
    final alignKey = GlobalKey();

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
                const SizedBox(width: 4),
                // --- Size mode selector ---
                GestureDetector(
                  key: modeKey,
                  onTap: () => _showPopup<GridSizeMode>(
                    context: context,
                    key: modeKey,
                    options: GridSizeMode.values,
                    selectedOption: row.sizeMode,
                    textFor: (m) => m.name,
                    onSelected: (m) {
                      row.sizeMode = m;
                      onChanged(row);
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      row.sizeMode.name,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // --- Alignment selector ---
                GestureDetector(
                  key: alignKey,
                  onTap: () => _showPopup<GridAlignment>(
                    context: context,
                    key: alignKey,
                    options: GridAlignment.values,
                    selectedOption: row.alignment,
                    iconFor: (a) => _iconFor(a, horizontal),
                    onSelected: (a) {
                      row.alignment = a;
                      onChanged(row);
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _iconFor(row.alignment, horizontal),
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // --- Size input ---
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: row.size.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) {
                      row.size = double.tryParse(v) ?? row.size;
                      onChanged(row);
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Adjust icons based on orientation (vertical or horizontal)
  IconData _iconFor(GridAlignment alignment, bool horizontal) {
    if (horizontal) {
      // horizontal alignment (columns)
      switch (alignment) {
        case GridAlignment.start:
          return Icons.align_horizontal_left;
        case GridAlignment.center:
          return Icons.align_horizontal_center;
        case GridAlignment.end:
          return Icons.align_horizontal_right;
        case GridAlignment.stretch:
          return Icons.height;
      }
    } else {
      // vertical alignment (rows)
      switch (alignment) {
        case GridAlignment.start:
          return Icons.vertical_align_top;
        case GridAlignment.center:
          return Icons.vertical_align_center;
        case GridAlignment.end:
          return Icons.vertical_align_bottom;
        case GridAlignment.stretch:
          return Icons.height;
      }
    }
  }

  void _showPopup<T>({
    required BuildContext context,
    required GlobalKey key,
    required List<T> options,
    required T selectedOption,
    required void Function(T) onSelected,
    IconData Function(T)? iconFor,
    String Function(T)? textFor,
  }) {
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context);
    final target = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => overlayEntry.remove(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: target.left,
              top: target.bottom,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((option) {
                      final bool selected = option == selectedOption;
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                          overlayEntry.remove();
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: selected ? Colors.blue.shade700 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: iconFor != null
                              ? Icon(
                            iconFor(option),
                            size: 16,
                            color: selected ? Colors.white : Colors.black87,
                          )
                              : Text(
                            textFor!(option),
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(overlayEntry);
  }
}
