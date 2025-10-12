import 'package:flutter/material.dart';

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumb({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isFirst = index == 0;
          final isLast = index == items.length - 1;

          return Transform.translate(
            offset: Offset(isFirst ? 0.0 : -13.0 * index, 0),
            child: _BreadcrumbItem(
              label: item.label,
              onTap: item.onTap,
              isFirst: isFirst,
              isLast: isLast,
            ),
          );
        }),
      ),
    );
  }
}

class _BreadcrumbItem extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _BreadcrumbItem({
    required this.label,
    this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_BreadcrumbItem> createState() => _BreadcrumbItemState();
}

class _BreadcrumbItemState extends State<_BreadcrumbItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClickable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          height: 36,
          child: CustomPaint(
            painter: _BreadcrumbShapePainter(
              isFirst: widget.isFirst,
              isLast: widget.isLast,
              isHovered: _isHovered && isClickable,
              isClickable: isClickable,
              backgroundColor: _isHovered && isClickable
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderColor: theme.colorScheme.outline.withOpacity(0.5),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: widget.isFirst ? 0 : 28, // flush first element
                right: 28,
                top: 0,
                bottom: 0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isLast
                        ? theme.colorScheme.onSurface
                        : (isClickable
                        ? (_isHovered
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.8))
                        : theme.colorScheme.onSurface.withOpacity(0.6)),
                    fontWeight:
                    widget.isLast ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbShapePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final bool isHovered;
  final bool isClickable;
  final Color backgroundColor;
  final Color borderColor;

  _BreadcrumbShapePainter({
    required this.isFirst,
    required this.isLast,
    required this.isHovered,
    required this.isClickable,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final chevronSize = 14.0;
    final path = Path();

    if (isFirst) {
      path.moveTo(0, 0);
      path.lineTo(size.width - chevronSize, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - chevronSize, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else if (isLast) {
      path.moveTo(0, 0);
      path.lineTo(size.width - chevronSize, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - chevronSize, size.height);
      path.lineTo(0, size.height);
      path.lineTo(chevronSize, size.height / 2);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width - chevronSize, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - chevronSize, size.height);
      path.lineTo(0, size.height);
      path.lineTo(chevronSize, size.height / 2);
      path.close();
    }

    // Fill
    canvas.drawPath(path, fillPaint);

    // Stroke path for chevron separators only, no top/bottom lines
    final separatorPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, separatorPaint);
  }

  @override
  bool shouldRepaint(_BreadcrumbShapePainter oldDelegate) {
    return oldDelegate.isHovered != isHovered ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor;
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}
