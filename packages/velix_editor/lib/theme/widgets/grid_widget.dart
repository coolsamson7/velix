import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../metadata/widgets/grid.dart';
import '../../theme/widget_builder.dart';
import '../../util/message_bus.dart';

import 'package:flutter/material.dart' show
BuildContext, Widget, Colors, Border, BorderStyle, BorderRadius,
BoxDecoration, FontStyle, TextStyle, Text, Center, Table, TableRow,
DragTarget, SizedBox, TableCellVerticalAlignment, EdgeInsets, Padding, Align, TableColumnWidth, FixedColumnWidth,
FlexColumnWidth, IntrinsicColumnWidth, Container, Alignment;

import 'package:velix/util/collections.dart';
import '../../commands/reparent_command.dart';
import '../../edit_widget.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';

@Injectable()
class GridEditWidgetBuilder extends WidgetBuilder<GridWidgetData> {
  final TypeRegistry typeRegistry;

  GridEditWidgetBuilder({required this.typeRegistry}) : super(name: "grid", edit: true);

  @override
  Widget create(GridWidgetData data, Environment environment, BuildContext context) {
    final spacing = data.spacing.toDouble();

    // Ensure we have at least some default columns/rows if empty
    if (data.cols.isEmpty || data.rows.isEmpty) {
      return Center(
        child: Text(
          'Grid has no rows or columns',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Determine column widths with proper defaults
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

    Widget _alignedCellContent(GridAlignment rowAlignment, GridAlignment colAlignment, Widget content) {
      // Combine row (vertical) and column (horizontal) alignment
      Alignment alignment;

      // Determine vertical alignment from row
      double vertical = switch (rowAlignment) {
        GridAlignment.start => -1.0,    // top
        GridAlignment.center => 0.0,    // center
        GridAlignment.end => 1.0,       // bottom
        GridAlignment.stretch => 0.0,
      };

      // Determine horizontal alignment from column
      double horizontal = switch (colAlignment) {
        GridAlignment.start => -1.0,    // left
        GridAlignment.center => 0.0,    // center
        GridAlignment.end => 1.0,       // right
        GridAlignment.stretch => 0.0,
      };

      alignment = Alignment(horizontal, vertical);

      // Handle stretch cases
      if (rowAlignment == GridAlignment.stretch && colAlignment == GridAlignment.stretch) {
        return SizedBox.expand(child: content);
      } else if (rowAlignment == GridAlignment.stretch) {
        return SizedBox(
          height: double.infinity,
          child: Align(alignment: alignment, child: content),
        );
      } else if (colAlignment == GridAlignment.stretch) {
        return SizedBox(
          width: double.infinity,
          child: Align(alignment: alignment, child: content),
        );
      }

      return Align(alignment: alignment, child: content);
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: columnWidths,
      defaultColumnWidth: const FlexColumnWidth(1.0), // CRITICAL: Default width for all columns
      children: List.generate(data.rows.length, (rowIndex) {
        final row = data.rows[rowIndex];

        return TableRow(
          children: List.generate(data.cols.length, (colIndex) {
            final col = data.cols[colIndex];

            final child = findElement(
              data.children,
                  (w) => w.cell?.row == rowIndex && w.cell?.col == colIndex,
            );

            Widget content = child != null ? EditWidget(model: child) : _buildDropArea(rowIndex, colIndex);

            // Apply row alignment
            content = _alignedCellContent(row.alignment, col.alignment, content);

            // Wrap with spacing
            return Padding(
              padding: EdgeInsets.all(spacing / 2),
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

    // Ensure we have at least some default columns/rows if empty
    if (data.cols.isEmpty || data.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    // Column widths based on GridItem config with proper defaults
    final columnWidths = <int, TableColumnWidth>{
      for (var i = 0; i < data.cols.length; i++)
        i: switch (data.cols[i].sizeMode) {
          GridSizeMode.fixed => FixedColumnWidth(data.cols[i].size),
          GridSizeMode.flex => FlexColumnWidth(data.cols[i].size),
          GridSizeMode.auto => const IntrinsicColumnWidth(),
        }
    };

    Widget _alignedCellContent(GridAlignment rowAlignment, GridAlignment colAlignment, Widget content) {
      // Combine row (vertical) and column (horizontal) alignment
      Alignment alignment;

      // Determine vertical alignment from row
      double vertical = switch (rowAlignment) {
        GridAlignment.start => -1.0,    // top
        GridAlignment.center => 0.0,    // center
        GridAlignment.end => 1.0,       // bottom
        GridAlignment.stretch => 0.0,
      };

      // Determine horizontal alignment from column
      double horizontal = switch (colAlignment) {
        GridAlignment.start => -1.0,    // left
        GridAlignment.center => 0.0,    // center
        GridAlignment.end => 1.0,       // right
        GridAlignment.stretch => 0.0,
      };

      alignment = Alignment(horizontal, vertical);

      // Handle stretch cases
      if (rowAlignment == GridAlignment.stretch && colAlignment == GridAlignment.stretch) {
        return SizedBox.expand(child: content);
      } else if (rowAlignment == GridAlignment.stretch) {
        return SizedBox(
          height: double.infinity,
          child: Align(alignment: alignment, child: content),
        );
      } else if (colAlignment == GridAlignment.stretch) {
        return SizedBox(
          width: double.infinity,
          child: Align(alignment: alignment, child: content),
        );
      }

      return Align(alignment: alignment, child: content);
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: columnWidths,
      defaultColumnWidth: const FlexColumnWidth(1.0), // CRITICAL: Default width for all columns
      children: List.generate(data.rows.length, (rowIndex) {
        final row = data.rows[rowIndex];

        return TableRow(
          children: List.generate(data.cols.length, (colIndex) {
            final child = findElement(
              data.children,
                  (w) => w.cell?.row == rowIndex && w.cell?.col == colIndex,
            );

            if (child != null) {
              Widget content = EditWidget(model: child);
              final col = data.cols[colIndex];
              content = _alignedCellContent(row.alignment, col.alignment, content);

              return Padding(
                padding: EdgeInsets.all(spacing / 2),
                child: content,
              );
            }

            // Empty cell with minimum size to prevent collapse
            return Padding(
              padding: EdgeInsets.all(spacing / 2),
              child: Container(
                constraints: const BoxConstraints(minHeight: 20, minWidth: 20),
                child: const SizedBox.shrink(),
              ),
            );
          }),
        );
      }),
    );
  }
}