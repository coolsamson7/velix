import 'package:flutter/material.dart';

/// A docked switchable panel that can appear on the left or right side.
import 'package:flutter/material.dart';

class DockedPanelSwitcher extends StatefulWidget {
  final Map<String, Widget Function(VoidCallback onClose)> panels;
  // panel name -> builder that receives onClose callback
  final Map<String, IconData> icons; // panel name -> icon
  final String? initialPanel;
  final DockSide side;
  final double barWidth;
  final double panelWidth;
  final ValueChanged<String?>? onPanelChanged; // callback when opened/closed

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

  @override
  void initState() {
    super.initState();
    selectedPanel = widget.initialPanel ?? widget.panels.keys.firstOrNull;
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

    final panel = selectedPanel == null
        ? const SizedBox.shrink()
        : AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(selectedPanel),
        width: widget.panelWidth,
        color: Colors.grey.shade100,
        child: widget.panels[selectedPanel]!(_closePanel),
      ),
    );

    return Row(
      children: isLeft ? [bar, panel] : [panel, bar],
    );
  }
}

enum DockSide { left, right }

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
