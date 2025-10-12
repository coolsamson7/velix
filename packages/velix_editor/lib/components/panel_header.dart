import 'package:flutter/material.dart';

class PanelHeader extends StatelessWidget {
  final String title;
  final String? tooltip; // ✅ new optional tooltip text
  final VoidCallback? onClose;
  final Widget? icon; // optional left-side icon

  const PanelHeader({
    super.key,
    required this.title,
    this.tooltip,
    this.onClose,
    this.icon,
  });

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
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],

          // ✅ Tooltip wraps the title text
          Tooltip(
            message: tooltip ?? title, // defaults to title if tooltip not provided
            waitDuration: const Duration(milliseconds: 400),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          const Spacer(),

          if (onClose != null)
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: Center(
                  child: Text(
                    '×',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Example wrapper that uses the header above a panel body
class PanelContainer extends StatelessWidget {
  // instance data

  final String title;
  final String? tooltip; // ✅ new optional tooltip text
  final Widget? icon;
  final Widget child;
  final VoidCallback? onClose;

  // constructor

  const PanelContainer({
    super.key,
    required this.title,
    this.tooltip,
    this.icon,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ makes content stretch full width
      children: [
        PanelHeader(
          title: title,
          tooltip: tooltip, // ✅ pass through
          icon: icon,
          onClose: onClose,
        ),
        Expanded(
          child: Container(
            alignment: Alignment.topLeft, // ✅ force top-left alignment
            child: SizedBox.expand(child: child),
          ),
        ),
      ],
    );
  }
}
