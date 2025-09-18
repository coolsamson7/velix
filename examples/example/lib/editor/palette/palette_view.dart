import 'package:flutter/material.dart' hide MetaData;

import '../components/panel_header.dart';
import '../metadata/metadata.dart';
import '../metadata/type_registry.dart';


class WidgetPalette extends StatefulWidget {
  final TypeRegistry typeRegistry;

  const WidgetPalette({super.key, required this.typeRegistry});

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
    for (var group in widget.typeRegistry.metaData.values.map((e) => e.group).toSet()) {
      _expandedGroups[group] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group widgets by group name
    final Map<String, List<MetaData>> groupedWidgets = {};
    for (var meta in widget.typeRegistry.metaData.values) {
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
          title: "Palette",
          onClose: () => {},
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

  Widget _buildGroup(String groupName, List<MetaData> widgetsInGroup) {
    final isExpanded = _expandedGroups[groupName] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
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
        // Widgets grid
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
                    return Draggable<String>(
                      data: type.name,
                      feedback: Material(
                        child: Opacity(
                          opacity: 0.8,
                          child: _buildPaletteItem(type, highlight: true),
                        ),
                      ),
                      child: _buildPaletteItem(type),
                    );
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPaletteItem(MetaData type, {bool highlight = false}) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? Colors.blueAccent : Colors.white,
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.widgets, size: 32), // generic icon
          const SizedBox(height: 4),
          Text(
            type.name,
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
