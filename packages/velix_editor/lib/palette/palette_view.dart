import 'package:flutter/material.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../components/panel_header.dart';
import '../metadata/metadata.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';

class _PaletteDraggable extends StatefulWidget {
  final WidgetDescriptor type;
  final Widget Function(bool highlight) itemBuilder;

  const _PaletteDraggable({required this.type, required this.itemBuilder, Key? key}) : super(key: key);

  @override
  State<_PaletteDraggable> createState() => _PaletteDraggableState();
}

class _PaletteDraggableState extends State<_PaletteDraggable> {
  late WidgetData dragInstance;

  @override
  void initState() {
    super.initState();
    dragInstance = widget.type.create();
  }

  void _newDragInstance() => setState(() { dragInstance = widget.type.create(); });

  @override
  Widget build(BuildContext context) {
    return Draggable<WidgetData>(
      data: dragInstance,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: widget.itemBuilder(true),
        ),
      ),
      childWhenDragging: widget.itemBuilder(false),
      child: widget.itemBuilder(false),
      onDragStarted: _newDragInstance,
    );
  }
}


class WidgetPalette extends StatefulWidget {
  final TypeRegistry typeRegistry;
  final VoidCallback onClose;

  const WidgetPalette({super.key, required this.onClose, required this.typeRegistry});

  @override
  State<WidgetPalette> createState() => _WidgetPaletteState();
}

class _WidgetPaletteState extends State<WidgetPalette> {
  double _width = 150; // initial width
  static const double _minWidth = 120;
  static const double _maxWidth = 400;

  // Track which groups are expanded
  final Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // initially expand all groups
    for (var group in widget.typeRegistry.descriptor.values.map((e) => e.group).toSet()) {
      _expandedGroups[group] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group widgets by group name
    final Map<String, List<WidgetDescriptor>> groupedWidgets = {};
    for (var meta in widget.typeRegistry.descriptor.values) {
      groupedWidgets.putIfAbsent(meta.group, () => []).add(meta);
    }

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _width = (_width + details.delta.dx).clamp(_minWidth, _maxWidth);
        });
      },
      child: Container(
        width: _width,
        color: Colors.grey.shade300,
        child: PanelContainer(
          title: "editor:docks.palette.label".tr(),
          onClose: widget.onClose,
          child: ListView(
            children: groupedWidgets.entries.map((entry) {
              final groupName = entry.key;
              final widgetsInGroup = entry.value;

              return _buildGroup(groupName, widgetsInGroup);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(String groupName, List<WidgetDescriptor> widgetsInGroup) {
    final isExpanded = _expandedGroups[groupName] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expandedGroups[groupName] = !isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 16),
                const SizedBox(width: 4),
                Text(
                  groupName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = 80.0;
                final crossAxisCount =
                (constraints.maxWidth / itemWidth).floor().clamp(1, 10);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: widgetsInGroup.map((type) {
                    return _PaletteDraggable(
                      type: type,
                      itemBuilder: (highlight) => _buildPaletteItem(type, highlight: highlight),
                    );
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }



  Widget _buildPaletteItem(WidgetDescriptor type, {bool highlight = false}) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? Colors.blueAccent : Colors.white,
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          type.icon,
          //const Icon(Icons.widgets, size: 32), // generic icon
          const SizedBox(height: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
