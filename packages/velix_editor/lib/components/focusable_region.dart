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

  bool get _hasFocusIncludingChildren =>
      _focusNode.hasFocus || _focusNode.hasPrimaryFocus || _focusNode.children.any((c) => c.hasFocus);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: "FocusableRegion");

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
      descendantsAreFocusable: true, // allow children to request focus
      child: InkWell(
        onTap: () {
          _focusNode.requestFocus();
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
