import 'package:flutter/material.dart';

class FocusableRegion extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool>? onFocusChange;
  final void Function(TapDownDetails)? onTapDown;
  final Color focusBorderColor;

  const FocusableRegion({
    super.key,
    required this.child,
    this.onFocusChange,
    this.onTapDown,
    this.focusBorderColor = Colors.blue,
  });

  @override
  State<FocusableRegion> createState() => _FocusableRegionState();
}

class _FocusableRegionState extends State<FocusableRegion> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: "FocusableRegion");
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        // Grab focus immediately
        _focusNode.requestFocus();

        // Forward to your widget logic
        widget.onTapDown?.call(details);
      },
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: widget.onFocusChange,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusNode.hasFocus
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