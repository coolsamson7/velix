import 'package:flutter/material.dart' show BuildContext, NeverScrollableScrollPhysics, Widget, GridView, SliverGridDelegateWithFixedCrossAxisCount, Border, Colors, BorderStyle, BorderRadius, BoxDecoration, FontStyle, TextStyle, Text, Center, Container, DragTarget;
import 'package:velix/util/collections.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../commands/reparent_command.dart';
import '../../edit_widget.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/grid.dart';
import '../../util/message_bus.dart';
import '../widget_builder.dart';

@Injectable()
class GridEditWidgetBuilder extends WidgetBuilder<GridWidgetData> {
  final TypeRegistry typeRegistry;

  GridEditWidgetBuilder({required this.typeRegistry})
      : super(name: "grid", edit: true);

  @override
  Widget create(GridWidgetData data, Environment environment, BuildContext context) {
    final rows = data.rows;
    final cols = data.cols;
    final spacing = data.spacing ?? 8.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: spacing.toDouble(),
        mainAxisSpacing: spacing.toDouble(),
      ),
      itemCount: rows * cols,
      itemBuilder: (context, index) {
        final row = index ~/ cols;
        final col = index % cols;

        // Find if there is a widget at (row, col)

        var child = findElement(data.children,  (w) => w.cell!.row == row && w.cell!.col == col);

        if (child != null) {
          return EditWidget(model: child);
        }

        // Empty slot = drop area
        return DragTarget<WidgetData>(
          onWillAccept: (widget) => data.acceptsChild(widget!),
          onAccept: (widget) {
            environment.get<CommandStack>().execute(
              ReparentCommand(
                bus: environment.get<MessageBus>(),
                widget: widget,
                newParent: data,
                newCell: Cell(row: row, col: col), // assign position
              ),
            );
          },
          builder: (context, candidateData, rejectedData) {
            final isActive = candidateData.isNotEmpty;
            return Container(
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
      },
    );
  }
}

@Injectable()
class GridWidgetBuilder extends WidgetBuilder<GridWidgetData> {
  final TypeRegistry typeRegistry;

  GridWidgetBuilder({required this.typeRegistry})
      : super(name: "grid");

  @override
  Widget create(GridWidgetData data, Environment environment, BuildContext context) {
    final rows = data.rows;
    final cols = data.cols;
    final spacing = data.spacing ?? 8.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: spacing.toDouble(),
        mainAxisSpacing: spacing.toDouble(),
      ),
      itemCount: rows * cols,
      itemBuilder: (context, index) {
        final row = index ~/ cols;
        final col = index % cols;

        // Find if there is a widget at (row, col)

        var child = findElement(data.children,  (w) => w.cell!.row == row && w.cell!.col == col);

        return child != null ?  EditWidget(model: child) : null;
      },
    );
  }
}
