import 'package:flutter/material.dart';

/// on overlay, that shows a spinner while active
class OverlaySpinner extends StatelessWidget {
  // instance data

  final bool show;
  final Widget child;

  // constructor

  const OverlaySpinner({
    super.key,
    required this.show,
    required this.child,
  });

  // override

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        if (show)  // last widget wins
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true, // disables clicks/keyboard/etc.
              child: Container(
                color: Colors.black38, // semi-transparent overlay
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}