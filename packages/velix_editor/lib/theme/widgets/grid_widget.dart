// --- SIMPLIFIED IMPORTS ---
import 'package:flutter/material.dart' show Alignment, TableCellVerticalAlignment, BuildContext, Widget, Center, TableColumnWidth, IntrinsicColumnWidth, BoxConstraints, FlexColumnWidth, SizedBox, Colors, TextStyle, Text, FixedColumnWidth, Border, BorderStyle, BorderRadius, BoxDecoration, FontStyle, Container, DragTarget, Align, EdgeInsets, Padding, TableCell, TableRow, Table;
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../metadata/widgets/grid.dart';
import '../../theme/widget_builder.dart';
import '../../util/message_bus.dart';

// Assuming these are all local/internal imports

import 'package:velix/util/collections.dart';
import '../../commands/reparent_command.dart';
import '../../edit_widget.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';

// --- Helper function to map GridAlignment to Flutter's Alignment ---
Alignment _mapGridAlignmentToFlutterAlignment(GridAlignment colAlignment, GridAlignment rowAlignment) {
  double horizontal = switch (colAlignment) {
    GridAlignment.start => -1.0,
    GridAlignment.center => 0.0,
    GridAlignment.end => 1.0,
    GridAlignment.stretch => 0.0, // Stretch handled by ColumnWidth
  };

  double vertical = switch (rowAlignment) {
    GridAlignment.start => -1.0,
    GridAlignment.center => 0.0,
    GridAlignment.end => 1.0,
    GridAlignment.stretch => 0.0, // Stretch handled by TableCellVerticalAlignment.fill
  };
  return Alignment(horizontal, vertical);
}

// --- Helper function to map GridAlignment to TableCellVerticalAlignment ---
TableCellVerticalAlignment _mapGridAlignmentToVertical(GridAlignment alignment) {
  return switch (alignment) {
    GridAlignment.start => TableCellVerticalAlignment.top,
    GridAlignment.center => TableCellVerticalAlignment.middle,
    GridAlignment.end => TableCellVerticalAlignment.bottom,
    GridAlignment.stretch => TableCellVerticalAlignment.fill,
  };
}


@Injectable()
class GridEditWidgetBuilder extends WidgetBuilder<GridWidgetData> {
  final TypeRegistry typeRegistry;

  GridEditWidgetBuilder({required this.typeRegistry}) : super(name: "grid", edit: true);

  @override
  Widget create(GridWidgetData data, Environment environment, BuildContext context) {
    final spacing = data.spacing.toDouble();

    if (data.cols.isEmpty || data.rows.isEmpty) {
      return const Center(
        child: Text(
          'Grid has no rows or columns',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final columnWidths = <int, TableColumnWidth>{
      for (var i = 0; i < data.cols.length; i++)
        i: switch (data.cols[i].sizeMode) {
          GridSizeMode.fixed => FixedColumnWidth(data.cols[i].size),
          GridSizeMode.flex => FlexColumnWidth(data.cols[i].size),
          GridSizeMode.auto => const IntrinsicColumnWidth(),
        }
    };

    Widget _buildDropArea(int rowIndex, int colIndex) {
      return DragTarget<WidgetData>(
        onWillAccept: (widget) => data.acceptsChild(widget!),
        onAccept: (widget) {
          environment.get<CommandStack>().execute(
            ReparentCommand(
              bus: environment.get<MessageBus>(),
              widget: widget,
              newParent: data,
              newCell: Cell(row: rowIndex, col: colIndex),
            ),
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty;
          return Container(
            constraints: const BoxConstraints(minHeight: 60, minWidth: 60),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? Colors.blue : Colors.grey,
                width: 1,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                isActive ? "Drop here" : "Empty",
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.blue : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        },
      );
    }

    // REMOVED _alignedCellContent to use TableCell properties instead
    // The old logic was redundant/incorrect for a Table structure.

    return Table(
      // Default vertical alignment for the table is fine, but it can be overridden per cell
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: columnWidths,
      defaultColumnWidth: const FlexColumnWidth(1.0),
      children: List.generate(data.rows.length, (rowIndex) {
        final row = data.rows[rowIndex];
        return TableRow(
          children: List.generate(data.cols.length, (colIndex) {
            final col = data.cols[colIndex];
            final childModel = findElement(
              data.children,
                  (w) => w.cell?.row == rowIndex && w.cell?.col == colIndex,
            );

            Widget content = childModel != null
                ? EditWidget(model: childModel)
                : _buildDropArea(rowIndex, colIndex);

            // 1. HORIZONTAL ALIGNMENT: Wrap the content in Align/Container
            //    to handle start/center/end/stretch horizontally.
            //    Note: Horizontal stretch is often handled by FlexColumnWidths.
            if (col.alignment != GridAlignment.stretch) {
              content = Align(
                alignment: _mapGridAlignmentToFlutterAlignment(col.alignment, GridAlignment.center),
                child: content,
              );
            }


            // 2. WRAP IN PADDING: Apply the spacing/padding
            content = Padding(
              padding: EdgeInsets.all(spacing / 2),
              child: content,
            );

            // 3. VERTICAL ALIGNMENT: MUST wrap in TableCell to communicate
            //    vertical alignment preference to the Table widget's layout.
            return TableCell(
              verticalAlignment: _mapGridAlignmentToVertical(row.alignment),
              child: content,
            );
          }),
        );
      }),
    );
  }
}

@Injectable()
class GridWidgetBuilder extends WidgetBuilder<GridWidgetData> {
  final TypeRegistry typeRegistry;

  GridWidgetBuilder({required this.typeRegistry}) : super(name: "grid");

  @override
  Widget create(GridWidgetData data, Environment environment, BuildContext context) {
    final spacing = data.spacing.toDouble();

    if (data.cols.isEmpty || data.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final columnWidths = <int, TableColumnWidth>{
      for (var i = 0; i < data.cols.length; i++)
        i: switch (data.cols[i].sizeMode) {
          GridSizeMode.fixed => FixedColumnWidth(data.cols[i].size),
          GridSizeMode.flex => FlexColumnWidth(data.cols[i].size),
          GridSizeMode.auto => const IntrinsicColumnWidth(),
        }
    };

    // REMOVED _alignedCellContent for the same reasons as above.

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: columnWidths,
      defaultColumnWidth: const FlexColumnWidth(1.0),
      children: List.generate(data.rows.length, (rowIndex) {
        final row = data.rows[rowIndex];
        return TableRow(
          children: List.generate(data.cols.length, (colIndex) {
            final col = data.cols[colIndex];
            final childModel = findElement(
              data.children,
                  (w) => w.cell?.row == rowIndex && w.cell?.col == colIndex,
            );

            Widget content;

            if (childModel != null) {
              content = EditWidget(model: childModel);

              // 1. HORIZONTAL ALIGNMENT: Wrap the content in Align/Container
              if (col.alignment != GridAlignment.stretch) {
                content = Align(
                  alignment: _mapGridAlignmentToFlutterAlignment(col.alignment, GridAlignment.center),
                  child: content,
                );
              }
            } else {
              // Empty cell placeholder
              content = const SizedBox.shrink();
            }

            // 2. WRAP IN PADDING: Apply the spacing/padding
            content = Padding(
              padding: EdgeInsets.all(spacing / 2),
              child: content,
            );

            // 3. VERTICAL ALIGNMENT: MUST wrap in TableCell
            return TableCell(
              verticalAlignment: _mapGridAlignmentToVertical(row.alignment),
              child: content,
            );
          }),
        );
      }),
    );
  }
}
