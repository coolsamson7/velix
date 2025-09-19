import 'package:flutter/material.dart';

typedef OnClose<T> = void Function(T value);

enum DockSide { left, right }

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class DockedPanelSwitcher extends StatefulWidget {
  final Map<String, Widget Function(VoidCallback onClose)> panels;
  final Map<String, IconData> icons;
  final String? initialPanel;
  final DockSide side;
  final double barWidth;
  final double panelWidth;
  final ValueChanged<String?>? onPanelChanged;

  const DockedPanelSwitcher({
    super.key,
    required this.panels,
    required this.icons,
    this.initialPanel,
    this.side = DockSide.left,
    this.barWidth = 40,
    this.panelWidth = 200,
    this.onPanelChanged,
  });

  @override
  State<DockedPanelSwitcher> createState() => _DockedPanelSwitcherState();
}

class _DockedPanelSwitcherState extends State<DockedPanelSwitcher> {
  String? selectedPanel;
  late double panelWidth;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    selectedPanel = widget.initialPanel ?? widget.panels.keys.firstOrNull;
    panelWidth = widget.panelWidth;
  }

  void _openPanel(String name) {
    setState(() {
      selectedPanel = (selectedPanel == name) ? null : name;
    });
    widget.onPanelChanged?.call(selectedPanel);
  }

  void _closePanel() {
    setState(() => selectedPanel = null);
    widget.onPanelChanged?.call(null);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      panelWidth += widget.side == DockSide.left ? details.delta.dx : -details.delta.dx;
      if (panelWidth < 100) panelWidth = 100;
      if (panelWidth > 600) panelWidth = 600;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.side == DockSide.left;

    final bar = Container(
      width: widget.barWidth,
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: widget.panels.keys.map((name) {
          return IconButton(
            icon: Icon(widget.icons[name] ?? Icons.help_outline),
            tooltip: name,
            color: selectedPanel == name ? Colors.blue : null,
            onPressed: () => _openPanel(name),
          );
        }).toList(),
      ),
    );

    final resizeHandle = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onDragUpdate,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.resizeLeftRight,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 8,
          color: _hovering ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          child: Center(
            child: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 2,
                    offset: const Offset(1, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final panel = selectedPanel == null
        ? const SizedBox.shrink()
        : AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(selectedPanel),
        width: panelWidth,
        color: Colors.grey.shade100,
        child: widget.panels[selectedPanel]!(_closePanel),
      ),
    );

    if (selectedPanel == null) {
      return Row(children: [bar]);
    }

    if (isLeft) {
      return Row(
        children: [
          bar,
          panel,
          resizeHandle,
        ],
      );
    } else {
      return Row(
        children: [
          resizeHandle,
          panel,
          bar,
        ],
      );
    }
  }
}
