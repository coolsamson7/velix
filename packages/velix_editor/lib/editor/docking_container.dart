import 'package:flutter/material.dart';
import 'package:velix_editor/editor/panel_switcher.dart';

/// Config for a docking panel
class Dock {
  final Map<String, Widget Function(VoidCallback onClose)> panels;
  final Map<String, IconData> icons;
  final String? initialPanel;
  final bool overlay;
  final double? size; // width for side, height for bottom

  const Dock({
    required this.panels,
    required this.icons,
    this.initialPanel,
    this.overlay = false,
    this.size,
  });
}

/// A container that arranges a central child with optional side/bottom panels
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

class _DockingContainerState extends State<DockingContainer> {
  double? leftSize;
  double? rightSize;
  double? bottomSize;

  String? leftPanel;
  String? rightPanel;
  String? bottomPanel;

  @override
  void initState() {
    super.initState();
    leftSize = widget.left?.size ?? 200;
    rightSize = widget.right?.size ?? 200;
    bottomSize = widget.bottom?.size ?? 200;

    leftPanel = widget.left?.initialPanel;
    rightPanel = widget.right?.initialPanel;
    bottomPanel = widget.bottom?.initialPanel;
  }

  @override
  Widget build(BuildContext context) {
    // If any panels are overlays, use Stack layout
    final hasOverlays = (widget.left?.overlay ?? false) ||
        (widget.right?.overlay ?? false) ||
        (widget.bottom?.overlay ?? false);

    if (hasOverlays) {
      return _buildStackLayout();
    } else {
      return _buildFlexLayout();
    }
  }

  Widget _buildStackLayout() {
    return Stack(
      children: [
        // Main content
        Positioned.fill(child: widget.child),

        // Overlay panels
        if (widget.left != null && widget.left!.overlay)
          _buildOverlayPanel(widget.left!, Alignment.centerLeft, leftPanel, leftSize!),

        if (widget.right != null && widget.right!.overlay)
          _buildOverlayPanel(widget.right!, Alignment.centerRight, rightPanel, rightSize!),

        if (widget.bottom != null && widget.bottom!.overlay)
          _buildOverlayPanel(widget.bottom!, Alignment.bottomCenter, bottomPanel, bottomSize!),
      ],
    );
  }

  Widget _buildOverlayPanel(
      Dock config, Alignment alignment, String? selectedPanel, double size) {
    final isBottom = alignment == Alignment.bottomCenter;
    return Align(
      alignment: alignment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isBottom ? null : (selectedPanel != null ? size : 40),
        height: isBottom ? (selectedPanel != null ? size : 40) : null,
        constraints: BoxConstraints(
          maxHeight: isBottom ? size : double.infinity,
          maxWidth: isBottom ? double.infinity : size,
        ),
        child: Material(
          elevation: 8,
          child: DockedPanelSwitcher(
            panels: config.panels,
            icons: config.icons,
            initialPanel: config.initialPanel,
            position: _getPositionFromAlignment(alignment),
            panelSize: size,
            onPanelChanged: (panel) => _updatePanelSelection(alignment, panel),
          ),
        ),
      ),
    );
  }


  Widget _buildFlexLayout() {
    Widget content = widget.child;

    // Wrap with bottom panel if present
    if (widget.bottom != null && !widget.bottom!.overlay) {
      content = Column(
        children: [
          Expanded(child: content),
          SizedBox(
            height: bottomPanel != null ? bottomSize! : 40, // Always allocate space for bar
            child: DockedPanelSwitcher(
              panels: widget.bottom!.panels,
              icons: widget.bottom!.icons,
              initialPanel: widget.bottom!.initialPanel,
              position: DockPosition.bottom,
              panelSize: bottomSize!,
              onPanelChanged: (panel) => setState(() => bottomPanel = panel),
              onSizeChanged: (size) => setState(() => bottomSize = size),
            ),
          ),
        ],
      );
    }

    // Wrap with side panels if present
    if (widget.left != null && !widget.left!.overlay ||
        widget.right != null && !widget.right!.overlay) {
      content = Row(
        children: [
          // Left panel
          if (widget.left != null && !widget.left!.overlay)
            SizedBox(
              width: leftPanel != null ? leftSize! : 40, // Always allocate space for bar
              child: DockedPanelSwitcher(
                panels: widget.left!.panels,
                icons: widget.left!.icons,
                initialPanel: widget.left!.initialPanel,
                position: DockPosition.left,
                panelSize: leftSize!,
                onPanelChanged: (panel) => setState(() => leftPanel = panel),
                onSizeChanged: (size) => setState(() => leftSize = size),
              ),
            ),

          // Main content - Always wrap in Expanded to handle flex layout
          Expanded(child: content),

          // Right panel
          if (widget.right != null && !widget.right!.overlay)
            SizedBox(
              width: rightPanel != null ? rightSize! : 40, // Always allocate space for bar
              child: DockedPanelSwitcher(
                panels: widget.right!.panels,
                icons: widget.right!.icons,
                initialPanel: widget.right!.initialPanel,
                position: DockPosition.right,
                panelSize: rightSize!,
                onPanelChanged: (panel) => setState(() => rightPanel = panel),
                onSizeChanged: (size) => setState(() => rightSize = size),
              ),
            ),
        ],
      );
    }

    return content;
  }

  DockPosition _getPositionFromAlignment(Alignment alignment) {
    switch (alignment) {
      case Alignment.centerLeft: return DockPosition.left;
      case Alignment.centerRight: return DockPosition.right;
      case Alignment.bottomCenter: return DockPosition.bottom;
      default: return DockPosition.left;
    }
  }

  void _updatePanelSelection(Alignment alignment, String? panel) {
    setState(() {
      switch (alignment) {
        case Alignment.centerLeft: leftPanel = panel; break;
        case Alignment.centerRight: rightPanel = panel; break;
        case Alignment.bottomCenter: bottomPanel = panel; break;
      }
    });
  }
}
