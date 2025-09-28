import 'package:flutter/material.dart';

typedef OnClose<T> = void Function(T value);

enum DockPosition { left, right, top, bottom }

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class DockedPanelSwitcher extends StatefulWidget {
  final Map<String, Widget Function(VoidCallback onClose)> panels;
  final Map<String, IconData> icons;
  final String? initialPanel;
  final DockPosition position;
  final double barSize; // width for left/right, height for top/bottom
  final double panelSize; // width for left/right, height for top/bottom
  final ValueChanged<String?>? onPanelChanged;
  final ValueChanged<double>? onSizeChanged;

  const DockedPanelSwitcher({
    super.key,
    required this.panels,
    required this.icons,
    this.initialPanel,
    this.position = DockPosition.left,
    this.barSize = 40,
    this.panelSize = 200,
    this.onPanelChanged,
    this.onSizeChanged,
  });

  @override
  State<DockedPanelSwitcher> createState() => _DockedPanelSwitcherState();
}

class _DockedPanelSwitcherState extends State<DockedPanelSwitcher> {
  String? selectedPanel;
  late double panelSize;
  bool _hovering = false;

  bool get isHorizontal =>
      widget.position == DockPosition.left || widget.position == DockPosition.right;

  @override
  void initState() {
    super.initState();
    selectedPanel = widget.initialPanel ?? widget.panels.keys.firstOrNull;
    panelSize = widget.panelSize;
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
    final delta = isHorizontal ? details.delta.dx : details.delta.dy;
    final newSize = panelSize + (widget.position == DockPosition.left || widget.position == DockPosition.top
        ? delta
        : -delta);

    final clampedSize = newSize.clamp(100.0, 600.0);

    if (clampedSize != panelSize) {
      setState(() => panelSize = clampedSize);
      widget.onSizeChanged?.call(clampedSize);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (selectedPanel == null) {
      return _buildBar();
    }

    final bar = _buildBar();
    final panel = Container(
      constraints: BoxConstraints(
        minWidth: isHorizontal ? 100 : 0,
        minHeight: isHorizontal ? 0 : 100,
        maxWidth: isHorizontal ? 600 : double.infinity,
        maxHeight: isHorizontal ? double.infinity : 600,
      ),
      child: _buildPanel(),
    );
    final resizeHandle = _buildResizeHandle();

    switch (widget.position) {
      case DockPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bar,
            SizedBox(width: panelSize, child: panel),
            resizeHandle,
          ],
        );
      case DockPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            resizeHandle,
            SizedBox(width: panelSize, child: panel),
            bar,
          ],
        );
      case DockPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bar,
            SizedBox(height: panelSize, child: panel),
            resizeHandle,
          ],
        );
      case DockPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            resizeHandle,
            SizedBox(height: panelSize, child: panel),
            bar,
          ],
        );
    }
  }


  Widget _buildBar() {
    if (isHorizontal) {
      return Container(
        width: widget.barSize,
        color: Colors.grey.shade200,
        child: Column(
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
    } else {
      return Container(
        height: widget.barSize,
        color: Colors.grey.shade200,
        child: Row(
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
    }
  }

  Widget _buildPanel() {
    return Container(
      color: Colors.grey.shade100,
      child: widget.panels[selectedPanel!]!(_closePanel),
    );
  }

  Widget _buildResizeHandle() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: isHorizontal
          ? SystemMouseCursors.resizeLeftRight
          : SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _onDragUpdate,
        child: Container(
          width: isHorizontal ? 8 : double.infinity,
          height: isHorizontal ? double.infinity : 8,
          color: _hovering ? Colors.blue.withOpacity(0.2) : Colors.grey.shade300,
          child: Center(
            child: Container(
              width: isHorizontal ? 2 : 20,
              height: isHorizontal ? 20 : 2,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}