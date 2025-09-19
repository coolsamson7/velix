import 'package:flutter/material.dart';


class LeftPanelSwitcher extends StatefulWidget {
  final Map<String, Widget> panels; // panel name -> widget
  const LeftPanelSwitcher({super.key, required this.panels});

  @override
  State<LeftPanelSwitcher> createState() => _LeftPanelSwitcherState();
}

class _LeftPanelSwitcherState extends State<LeftPanelSwitcher> {
  String selectedPanel = "tree";

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Vertical Icon Bar
        Container(
          width: 40,
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.account_tree),
                tooltip: "Tree",
                color: selectedPanel == "tree" ? Colors.blue : null,
                onPressed: () => setState(() => selectedPanel = "tree"),
              ),
              IconButton(
                icon: const Icon(Icons.widgets),
                tooltip: "Palette",
                color: selectedPanel == "palette" ? Colors.blue : null,
                onPressed: () => setState(() => selectedPanel = "palette"),
              ),
              IconButton(
                icon: const Icon(Icons.code),
                tooltip: "JSON",
                color: selectedPanel == "json" ? Colors.blue : null,
                onPressed: () => setState(() => selectedPanel = "json"),
              ),
            ],
          ),
        ),

        // Left Panel
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(selectedPanel),
            width: 200,
            color: Colors.grey.shade100,
            child: widget.panels[selectedPanel]!,
          ),
        ),
      ],
    );
  }
}