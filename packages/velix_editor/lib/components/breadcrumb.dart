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
            offset: Offset(isFirst ? 0.0 : -13.0 * index, 0), // Cumulative overlap
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
          height: 36, // Fixed height for proper clipping
          child: CustomPaint(
            painter: _BreadcrumbShapePainter(
              isFirst: widget.isFirst,
              isLast: widget.isLast,
              isHovered: _isHovered && isClickable,
              isClickable: isClickable,
              backgroundColor: _isHovered && isClickable
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderColor: _isHovered && isClickable
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.5),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: widget.isFirst ? 16 : 28, // Extra space for left notch
                right: 28, // Space for right chevron
                top: 8,
                bottom: 8,
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
                    fontWeight: widget.isLast ? FontWeight.w600 : FontWeight.w500,
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
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.miter;

    final chevronSize = 14.0;
    final path = Path();

    if (isFirst) {
      // First item: flat left side, chevron pointing right
      path.moveTo(0, 0);
      path.lineTo(size.width - chevronSize, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - chevronSize, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else if (isLast) {
      // Last item: chevron on both sides (same as middle)
      path.moveTo(0, 0);
      path.lineTo(size.width - chevronSize, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - chevronSize, size.height);
      path.lineTo(0, size.height);
      path.lineTo(chevronSize, size.height / 2);
      path.close();
    } else {
      // Middle items: chevron pointing right on left, chevron pointing right on right
      path.moveTo(0, 0);
      path.lineTo(size.width - chevronSize, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - chevronSize, size.height);
      path.lineTo(0, size.height);
      path.lineTo(chevronSize, size.height / 2);
      path.close();
    }

    // Draw fill
    canvas.drawPath(path, paint);

    // Draw border
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

  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}

// Example usage widget
class BreadcrumbExample extends StatelessWidget {
  const BreadcrumbExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breadcrumb Examples')),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arrow-shaped Breadcrumbs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Breadcrumb(
                items: [
                  BreadcrumbItem(
                    label: 'Home',
                    onTap: () => debugPrint('Navigate to Home'),
                  ),
                  BreadcrumbItem(
                    label: 'Products',
                    onTap: () => debugPrint('Navigate to Products'),
                  ),
                  BreadcrumbItem(
                    label: 'Electronics',
                    onTap: () => debugPrint('Navigate to Electronics'),
                  ),
                  const BreadcrumbItem(
                    label: 'Laptops',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Two items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Breadcrumb(
                items: [
                  BreadcrumbItem(
                    label: 'Dashboard',
                    onTap: () => debugPrint('Navigate to Dashboard'),
                  ),
                  const BreadcrumbItem(
                    label: 'Settings',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Long path',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Breadcrumb(
                items: [
                  BreadcrumbItem(
                    label: 'Home',
                    onTap: () => debugPrint('Navigate to Home'),
                  ),
                  BreadcrumbItem(
                    label: 'Documents',
                    onTap: () => debugPrint('Navigate to Documents'),
                  ),
                  BreadcrumbItem(
                    label: 'Projects',
                    onTap: () => debugPrint('Navigate to Projects'),
                  ),
                  BreadcrumbItem(
                    label: '2024',
                    onTap: () => debugPrint('Navigate to 2024'),
                  ),
                  BreadcrumbItem(
                    label: 'Q4',
                    onTap: () => debugPrint('Navigate to Q4'),
                  ),
                  const BreadcrumbItem(
                    label: 'Reports',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}