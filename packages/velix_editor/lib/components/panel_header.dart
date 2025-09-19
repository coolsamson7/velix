import 'package:flutter/material.dart';

// Reusable panel header with a title and close button
class PanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const PanelHeader({super.key, required this.title, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade400, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (onClose != null)
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}

/// Example wrapper that uses the header above a panel body
class PanelContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;

  const PanelContainer({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PanelHeader(title: title, onClose: onClose),
        Expanded(child: child),
      ],
    );
  }
}