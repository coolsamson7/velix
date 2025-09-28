import 'package:flutter/material.dart';

class BottomErrorDisplay extends StatelessWidget {
  final List<String> errors;

  const BottomErrorDisplay({super.key, this.errors = const ["ocuh"]});

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: Colors.red.shade600,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (e) => Text(
                  e,
                  style: const TextStyle(color: Colors.white),
                ),
              )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
