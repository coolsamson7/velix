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
  late FocusScopeNode _focusScopeNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusScopeNode = FocusScopeNode(debugLabel: 'FocusableRegionScope');

    _focusScopeNode.addListener(() {
      final hasFocus = _focusScopeNode.hasFocus;
      if (hasFocus != _hasFocus) {
        setState(() => _hasFocus = hasFocus);
        widget.onFocusChange?.call(hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusScopeNode,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // If no child grabs focus, focus the scope itself
          if (!_focusScopeNode.hasFocus) {
            _focusScopeNode.requestFocus();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hasFocus ? widget.focusBorderColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// NEW

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
