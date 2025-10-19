import 'package:flutter/material.dart';
import 'package:velix_editor/editor/panel_switcher.dart';
import 'package:velix_editor/editor/settings.dart';


class Panel {
  String name;
  String label;
  String tooltip;
  IconData? icon;
  Function(VoidCallback onClose) create;

  Panel({
    required this.name,
    required this.label,
    required this.icon,
    required this.create,
    required this.tooltip,
  });
}

class Dock {
  final List<Panel> panels;
  final String? initialPanel;
  final bool overlay;
  final double? size; // width for side, height for bottom

  const Dock({
    required this.panels,
    this.initialPanel,
    this.overlay = false,
    this.size,
  });
}

/// Container that arranges a central child with optional side/bottom panels
class DockingContainer extends StatefulWidget {
  final Widget child;
  final Dock? left;
  final Dock? right;
  final Dock? bottom;

  const DockingContainer({
    super.key,
    required this.child,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  State<DockingContainer> createState() => _DockingContainerState();
}

class _DockingContainerState extends State<DockingContainer> with StatefulMixin {
  @override
  String get stateName => "dockingContainer";

  @override
  Future<void> apply(Map<String, dynamic> data) async {
    // Could restore general container state here if needed
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    // Could write general container state here if needed
  }

  @override
  Widget build(BuildContext context) {
    final hasOverlays = (widget.left?.overlay ?? false) ||
        (widget.right?.overlay ?? false) ||
        (widget.bottom?.overlay ?? false);

    return hasOverlays ? _buildStackLayout() : _buildFlexLayout();
  }

  Widget _buildStackLayout() {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (widget.left != null && widget.left!.overlay)
          SidePanelWidget(dock: widget.left!, position: DockPosition.left),
        if (widget.right != null && widget.right!.overlay)
          SidePanelWidget(dock: widget.right!, position: DockPosition.right),
        if (widget.bottom != null && widget.bottom!.overlay)
          SidePanelWidget(dock: widget.bottom!, position: DockPosition.bottom),
      ],
    );
  }

  Widget _buildFlexLayout() {
    Widget content = widget.child;

    if (widget.bottom != null && !widget.bottom!.overlay) {
      content = Column(
        children: [
          Expanded(child: content),
          SidePanelWidget(dock: widget.bottom!, position: DockPosition.bottom),
        ],
      );
    }

    if ((widget.left != null && !widget.left!.overlay) ||
        (widget.right != null && !widget.right!.overlay)) {
      content = Row(
        children: [
          if (widget.left != null && !widget.left!.overlay)
            SidePanelWidget(dock: widget.left!, position: DockPosition.left),
          Expanded(child: content),
          if (widget.right != null && !widget.right!.overlay)
            SidePanelWidget(dock: widget.right!, position: DockPosition.right),
        ],
      );
    }

    return content;
  }
}

/// Wraps a dock as a stateful panel that remembers its size and open panel
class SidePanelWidget extends StatefulWidget {
  final Dock dock;
  final DockPosition position;

  const SidePanelWidget({super.key, required this.dock, required this.position});

  @override
  State<SidePanelWidget> createState() => _SidePanelWidgetState();
}

class _SidePanelWidgetState extends State<SidePanelWidget> with StatefulMixin {
  late double panelSize = widget.dock.size ?? 200;
  String? selectedPanel;

  @override
  String get stateName => "panel-${widget.position.name}";

  @override
  Future<void> apply(Map<String, dynamic> data) async {
    if ( data["panelSize"] != null)
      panelSize = data["panelSize"] ?? widget.dock.size ?? 200;
    else
      panelSize = widget.dock.size ?? 200;

    if (data["selectedPanel"] != null)
      selectedPanel = data["selectedPanel"];
    else
      selectedPanel = widget.dock.initialPanel;
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    data["panelSize"] = panelSize;
    data["selectedPanel"] = selectedPanel;
  }

  void _onPanelChanged(String? panel) {
    setState(() => selectedPanel = panel);

    writeSettings();
    flushSettings();
  }

  void _onSizeChanged(double size) {
    setState(() => panelSize = size);

    writeSettings();
    flushSettings();
  }

  @override
  Widget build(BuildContext context) {
    return DockedPanelSwitcher(
      panels: widget.dock.panels,
      initialPanel: selectedPanel,
      position: widget.position,
      panelSize: panelSize,
      onPanelChanged: _onPanelChanged,
      onSizeChanged: _onSizeChanged,
    );
  }
}
