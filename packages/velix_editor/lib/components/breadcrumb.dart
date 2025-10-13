import 'package:flutter/material.dart';

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Widget separator;

  const Breadcrumb({
    super.key,
    required this.items,
    this.separator = const _ChevronSeparator(),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildItems(),
      ),
    );
  }

  List<Widget> _buildItems() {
    final children = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      // Add breadcrumb item
      children.add(
        _BreadcrumbButton(
          label: item.label,
          onTap: item.onTap,
          isLast: isLast,
        ),
      );

      // Add separator (except after last item)
      if (!isLast) {
        children.add(separator);
      }
    }

    return children;
  }
}

class _BreadcrumbButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  const _BreadcrumbButton({
    required this.label,
    this.onTap,
    required this.isLast,
  });

  @override
  State<_BreadcrumbButton> createState() => _BreadcrumbButtonState();
}

class _BreadcrumbButtonState extends State<_BreadcrumbButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClickable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isHovered && isClickable
                  ? theme.colorScheme.primary.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
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
                fontWeight: widget.isLast ? FontWeight.w500 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronSeparator extends StatelessWidget {
  const _ChevronSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}

// Vertical line separator
class _VerticalLineSeparator extends StatelessWidget {
  const _VerticalLineSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 20,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.0),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

// Slash separator with better styling
class _SlashSeparator extends StatelessWidget {
  const _SlashSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '/',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

// Arrow separator
class _ArrowSeparator extends StatelessWidget {
  const _ArrowSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }
}

// Dot separator with proper height
class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
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

// Separator options
class BreadcrumbSeparators {
  static const chevron = _ChevronSeparator();
  static const verticalLine = _VerticalLineSeparator();
  static const slash = _SlashSeparator();
  static const arrow = _ArrowSeparator();
  static const dot = _DotSeparator();
}

// Example usage widget
class BreadcrumbExample extends StatelessWidget {
  const BreadcrumbExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breadcrumb Examples')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExample(
              'Chevron Separator (Default)',
              BreadcrumbSeparators.chevron,
            ),
            const SizedBox(height: 30),
            _buildExample(
              'Vertical Line Separator',
              BreadcrumbSeparators.verticalLine,
            ),
            const SizedBox(height: 30),
            _buildExample(
              'Slash Separator',
              BreadcrumbSeparators.slash,
            ),
            const SizedBox(height: 30),
            _buildExample(
              'Arrow Separator',
              BreadcrumbSeparators.arrow,
            ),
            const SizedBox(height: 30),
            _buildExample(
              'Dot Separator',
              BreadcrumbSeparators.dot,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(String title, Widget separator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Breadcrumb(
            separator: separator,
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
      ],
    );
  }
}