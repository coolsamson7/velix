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
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: separator,
        ));
      }
    }

    return children;
  }
}

class _BreadcrumbButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  const _BreadcrumbButton({
    required this.label,
    this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClickable = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: isLast
                  ? theme.colorScheme.onSurface
                  : (isClickable ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6)),
              fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
              decoration: isClickable && !isLast ? TextDecoration.underline : null,
              decorationColor: theme.colorScheme.primary,
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
    return Icon(
      Icons.chevron_right,
      size: 16,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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

// Simple separator options
class BreadcrumbSeparators {
  static const chevron = _ChevronSeparator();

  static const slash = Text('/',
      style: TextStyle(fontSize: 16, color: Colors.grey));

  static const dot = Text('•',
      style: TextStyle(fontSize: 16, color: Colors.grey));
}