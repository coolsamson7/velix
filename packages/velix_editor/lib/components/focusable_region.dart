import 'package:flutter/material.dart';

/// A focus-aware region that can activate when clicked.
/// Use it to define keyboard focus scopes (e.g., tree, canvas, inspector)
/// and visually or logically distinguish the currently active group.
class FocusGroup extends StatefulWidget {
  final Widget Function(BuildContext context, bool isActive) builder;
  final ValueChanged<bool>? onActiveChanged;
  final bool autofocus;

  const FocusGroup({
    super.key,
    required this.builder,
    this.onActiveChanged,
    this.autofocus = false,
  });

  @override
  State<FocusGroup> createState() => _FocusGroupState();
}

class _FocusGroupState extends State<FocusGroup> {
  late FocusNode _focusNode;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      debugLabel: 'FocusGroup',
      // Allow descendants to be focusable
      skipTraversal: false,
    );
    _focusNode.addListener(_handleFocusChange);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _handleFocusChange() {
    // Check if this node or any descendant has focus
    final nowActive = _focusNode.hasFocus || _hasDescendantFocus();
    if (nowActive != _isActive) {
      setState(() => _isActive = nowActive);
      widget.onActiveChanged?.call(nowActive);
    }
  }

  bool _hasDescendantFocus() {
    for (final child in _focusNode.descendants) {
      if (child.hasFocus) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _requestFocus() {
    // If no descendant has focus, focus the first focusable descendant or this node
    if (!_focusNode.hasFocus && !_hasDescendantFocus()) {
      final firstFocusable = _focusNode.descendants.firstWhere(
            (node) => node.canRequestFocus,
        orElse: () => _focusNode,
      );
      firstFocusable.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Use onTapDown instead of onTap to capture clicks earlier
      onTapDown: (_) => _requestFocus(),
      behavior: HitTestBehavior.translucent,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: false, // This node itself shouldn't steal focus
        onFocusChange: (hasFocus) => _handleFocusChange(),
        child: widget.builder(context, _isActive),
      ),
    );
  }
}
