import 'package:flutter/material.dart';

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumb({super.key, required this.items});

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
            offset: Offset(isFirst ? 0.0 : -12.0 * index, 0), // lighter overlap
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
                  : theme.colorScheme.surfaceVariant.withOpacity(0.15),
              borderColor: _isHovered && isClickable
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.4),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: widget.isFirst ? 0 : 16, // flush first element
                right: 16,
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
    final chevronSize = 12.0;
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

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
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

  const BreadcrumbItem({required this.label, this.onTap});
}

/// Example usage
class BreadcrumbExample extends StatelessWidget {
  const BreadcrumbExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breadcrumb Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Arrow-shaped Breadcrumbs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Breadcrumb(
              items: [
                BreadcrumbItem(label: 'Home', onTap: () {}),
                BreadcrumbItem(label: 'Products', onTap: () {}),
                BreadcrumbItem(label: 'Electronics', onTap: () {}),
                const BreadcrumbItem(label: 'Laptops'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
