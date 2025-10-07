import 'package:flutter/material.dart';

class FocusableRegion extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool>? onFocusChange;
  final Color focusBorderColor;

  const FocusableRegion({
    super.key,
    required this.child,
    this.onFocusChange,
    this.focusBorderColor = Colors.blue,
  });

  @override
  State<FocusableRegion> createState() => _FocusableRegionState();
}

class _FocusableRegionState extends State<FocusableRegion> {
  late FocusNode _focusNode;

  bool get _hasFocusIncludingChildren {
    // Check if this node or any descendant has focus
    return _focusNode.hasFocus || _hasDescendantFocus(_focusNode);
  }

  bool _hasDescendantFocus(FocusNode node) {
    // Recursively check if any descendant has focus
    for (final child in node.descendants) {
      if (child.hasFocus) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      debugLabel: "FocusableRegion",
      // This allows the focus node to track descendant focus changes
      skipTraversal: true,
    );

    _focusNode.addListener(_updateFocus);
  }

  void _updateFocus() {
    setState(() {}); // rebuild border
    widget.onFocusChange?.call(_hasFocusIncludingChildren);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_updateFocus);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      // Key: This allows descendants to be focusable
      canRequestFocus: false,
      // This ensures child focus changes trigger parent listener
      onFocusChange: (hasFocus) {
        _updateFocus();
      },
      child: GestureDetector(
        // Use GestureDetector instead of InkWell for better control
        onTap: () {
          // Find the first focusable descendant and focus it
          final firstFocusable = _focusNode.descendants.firstWhere(
                (node) => node.canRequestFocus,
            orElse: () => _focusNode,
          );
          firstFocusable.requestFocus();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hasFocusIncludingChildren
                  ? widget.focusBorderColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}