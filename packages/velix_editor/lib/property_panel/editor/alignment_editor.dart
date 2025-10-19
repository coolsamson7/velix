import 'package:flutter/material.dart' show CrossAxisAlignment, MainAxisAlignment, MainAxisSize, BorderStyle, Widget, ValueChanged;
import 'package:velix_di/di/di.dart';

import 'package:flutter/material.dart';
import 'package:velix_editor/metadata/widgets/column.dart';
import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/row.dart';
import '../../util/message_bus.dart';


import '../enum_editor.dart';

@Injectable()
class CrossAxisAlignmentBuilder extends AbstractEnumBuilder<CrossAxisAlignment> {
  // instance data

  bool horizontal = true;

  // constructor

  CrossAxisAlignmentBuilder() : super(values: CrossAxisAlignment.values);

  // override

  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required WidgetData widget,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    final alignment = value as CrossAxisAlignment;
    final key = GlobalKey();
    bool isHovered = false;
    horizontal = object is RowWidgetData; // ?

    return StatefulBuilder(builder: (context, setState) {
      return IntrinsicWidth(
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [ MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: isHovered ? Colors.grey.shade200 : Colors.transparent,
          child: GestureDetector(
            key: key,
            onTap: () => _showPopup(
              context: context,
              key: key,
              options: values,
              selectedOption: alignment,
              iconFor: _iconFor,
              onSelected: (a) {
                onChanged(a);
                setState(() {}); // refresh the icon
              },
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _iconFor(alignment),
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      )]
          )
      );
    });
  }

  /// Maps CrossAxisAlignment to a matching Material icon
  IconData _iconFor(CrossAxisAlignment align) {
    switch (align) {
      case CrossAxisAlignment.start:
        return horizontal ? Icons.align_horizontal_left : Icons.vertical_align_top;

      case CrossAxisAlignment.center:
        return horizontal ? Icons.align_horizontal_center : Icons.vertical_align_center;

      case CrossAxisAlignment.end:
        return horizontal ? Icons.align_horizontal_right : Icons.vertical_align_bottom;

      case CrossAxisAlignment.stretch:
      // “Stretch” means fill the entire axis — use expansion-like icons
        return horizontal ? Icons.unfold_more : Icons.unfold_more; // symmetrical, works for both

      case CrossAxisAlignment.baseline:
      // “Baseline” refers to text alignment — use a text-alignment-style icon
        return horizontal ? Icons.text_decrease : Icons.text_increase;
    }
  }

  void _showPopup<T>({
    required BuildContext context,
    required GlobalKey key,
    required List<T> options,
    required T selectedOption,
    required void Function(T) onSelected,
    required IconData Function(T) iconFor,
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
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blue.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            iconFor(option),
                            size: 18,
                            color: selected
                                ? Colors.white
                                : Colors.black87,
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



@Injectable()
class MainAxisAlignmentBuilder extends AbstractEnumBuilder<MainAxisAlignment> {
  // instance data

  bool horizontal = true;

  // constructor

  MainAxisAlignmentBuilder() : super(values: MainAxisAlignment.values);

  // override

  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required WidgetData widget,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    final alignment = value as MainAxisAlignment;
    final key = GlobalKey();
    bool isHovered = false;
    horizontal = object is ColumnWidgetData; // ?

    return StatefulBuilder(builder: (context, setState) {
      return IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: isHovered ? Colors.grey.shade200 : Colors.transparent,
          child: GestureDetector(
            key: key,
            onTap: () => _showPopup(
              context: context,
              key: key,
              options: MainAxisAlignment.values,
              selectedOption: alignment,
              iconFor: _iconFor,
              onSelected: (a) {
                onChanged(a);
                setState(() {}); // refresh the icon
              },
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _iconFor(alignment),
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      )]
      )
      );
    });
  }

  /// Maps MainAxisAlignment to a matching Material icon
  IconData _iconFor(MainAxisAlignment align) {
    switch (align) {
      case MainAxisAlignment.start:
        return horizontal ? Icons.align_horizontal_left : Icons.vertical_align_top;

      case MainAxisAlignment.center:
        return horizontal ? Icons.align_horizontal_center : Icons.vertical_align_center;

      case MainAxisAlignment.end:
        return horizontal ? Icons.align_horizontal_right : Icons.vertical_align_bottom;

      case MainAxisAlignment.spaceBetween:
        return horizontal ? Icons.space_bar : Icons.more_vert;

      case MainAxisAlignment.spaceAround:
        return horizontal ? Icons.align_horizontal_center_outlined : Icons.align_vertical_center_outlined;

      case MainAxisAlignment.spaceEvenly:
        return horizontal ? Icons.linear_scale : Icons.drag_handle;
    }
  }

  void _showPopup<T>({
    required BuildContext context,
    required GlobalKey key,
    required List<T> options,
    required T selectedOption,
    required void Function(T) onSelected,
    required IconData Function(T) iconFor,
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
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blue.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            iconFor(option),
                            size: 18,
                            color: selected
                                ? Colors.white
                                : Colors.black87,
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


@Injectable()
class MainAxisSizeBuilder extends AbstractEnumBuilder<MainAxisSize> {
  MainAxisSizeBuilder() : super(values: MainAxisSize.values);

  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required WidgetData widget,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    final selected = value as MainAxisSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: MainAxisSize.values.map((option) {
        final selectedState = option == selected;
        final icon = _iconFor(option);

        return GestureDetector(
          onTap: () => onChanged(option),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selectedState ? Colors.blue.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: selectedState ? Colors.white : Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(MainAxisSize size) {
    switch (size) {
      case MainAxisSize.min:
      // “Shrink to fit” icon — narrow horizontal bar
        return Icons.compress;
      case MainAxisSize.max:
      // “Expand to fill” icon — arrows outward
        return Icons.expand;
    }
  }
}

@Injectable()
class BorderStyleBuilder extends AbstractEnumBuilder<BorderStyle> {
  BorderStyleBuilder():super(values: BorderStyle.values);
}
