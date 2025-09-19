import 'package:flutter/material.dart';

/// A docked switchable panel that can appear on the left or right side.
class DockedPanelSwitcher extends StatefulWidget {
  final Map<String, Widget> panels; // panel name -> widget
  final Map<String, IconData> icons; // panel name -> icon
  final String initialPanel;
  final DockSide side;
  final double barWidth;
  final double panelWidth;

  const DockedPanelSwitcher({
    super.key,
    required this.panels,
    required this.icons,
    this.initialPanel = "",
    this.side = DockSide.left,
    this.barWidth = 40,
    this.panelWidth = 200,
  });

  @override
  State<DockedPanelSwitcher> createState() => _DockedPanelSwitcherState();
}

class _DockedPanelSwitcherState extends State<DockedPanelSwitcher> {
  late String selectedPanel;

  @override
  void initState() {
    super.initState();
    selectedPanel = widget.initialPanel.isNotEmpty
        ? widget.initialPanel
        : widget.panels.keys.first;
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
            onPressed: () => setState(() => selectedPanel = name),
          );
        }).toList(),
      ),
    );

    final panel = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(selectedPanel),
        width: widget.panelWidth,
        color: Colors.grey.shade100,
        child: widget.panels[selectedPanel]!,
      ),
    );

    return Row(
      children: isLeft ? [bar, panel] : [panel, bar],
    );
  }
}

enum DockSide { left, right }