import 'package:flutter/material.dart' show
BuildContext, Widget, Colors, Border, BorderStyle, BorderRadius,
BoxDecoration, FontStyle, TextStyle, Text, Center, Table, TableRow,
DragTarget, SizedBox, TableCellVerticalAlignment, EdgeInsets, Padding,
Align, TableColumnWidth, FixedColumnWidth, FlexColumnWidth,
IntrinsicColumnWidth, Container, Alignment;

import 'package:velix/util/collections.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../commands/reparent_command.dart';
import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/grid.dart';
import '../../util/message_bus.dart';
import '../widget_builder.dart';

@Injectable()
class GridEditWidgetBuilder extends WidgetBuilder<GridWidgetData> {
  final TypeRegistry typeRegistry;

  GridEditWidgetBuilder({required this.typeRegistry}) : super(name: "grid", edit: true);

  @override
  Widget create(GridWidgetData data, Environment environment, BuildContext context) {
    final spacing = data.spacing.toDouble();

    // --- Column width definitions ---
    final columnWidths = {
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
            height: 60,
            width: 80, // ✅ minimum visual size for empty auto cells
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

    Widget _alignedCell(GridAlignment alignment, Widget content) {
      switch (alignment) {
        case GridAlignment.start:
          return Align(alignment: Alignment.topLeft, child: content);
        case GridAlignment.center:
          return Align(alignment: Alignment.center, child: content);
        case GridAlignment.end:
          return Align(alignment: Alignment.bottomRight, child: content);
        case GridAlignment.stretch:
          return SizedBox.expand(child: content);
      }
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: columnWidths,
      children: List.generate(data.rows.length, (rowIndex) {
        final row = data.rows[rowIndex];

        return TableRow(
          children: List.generate(data.cols.length, (colIndex) {
            final child = findElement(
              data.children,
                  (w) => w.cell?.row == rowIndex && w.cell?.col == colIndex,
            );

            Widget content = child != null
                ? EditWidget(model: child)
                : _buildDropArea(rowIndex, colIndex);

            // Apply alignment + spacing
            content = Padding(
              padding: EdgeInsets.all(spacing / 2),
              child: _alignedCell(row.alignment, content),
            );

            return content;
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

    final columnWidths = {
      for (var i = 0; i < data.cols.length; i++)
        i: switch (data.cols[i].sizeMode) {
          GridSizeMode.fixed => FixedColumnWidth(data.cols[i].size),
          GridSizeMode.flex => FlexColumnWidth(data.cols[i].size),
          GridSizeMode.auto => const IntrinsicColumnWidth(),
        }
    };

    Widget _alignedCell(GridAlignment alignment, Widget content) {
      switch (alignment) {
        case GridAlignment.start:
          return Align(alignment: Alignment.topLeft, child: content);
        case GridAlignment.center:
          return Align(alignment: Alignment.center, child: content);
        case GridAlignment.end:
          return Align(alignment: Alignment.bottomRight, child: content);
        case GridAlignment.stretch:
          return SizedBox.expand(child: content);
      }
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: columnWidths,
      children: List.generate(data.rows.length, (rowIndex) {
        final row = data.rows[rowIndex];

        return TableRow(
          children: List.generate(data.cols.length, (colIndex) {
            final child = findElement(
              data.children,
                  (w) => w.cell?.row == rowIndex && w.cell?.col == colIndex,
            );

            if (child == null) {
              return const SizedBox(width: 80, height: 60); // visible placeholder for auto sizing
            }

            Widget content = DynamicWidget(model: child, meta: typeRegistry[child.type], parent: data);
            content = _alignedCell(row.alignment, content);

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
