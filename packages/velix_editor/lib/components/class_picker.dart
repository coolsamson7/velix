import 'package:flutter/material.dart';

import '../actions/types.dart';

class ClassPickerDialog extends StatefulWidget {
  final ClassRegistry registry;

  const ClassPickerDialog({required this.registry, super.key});

  @override
  State<ClassPickerDialog> createState() => _ClassPickerDialogState();
}

class _ClassPickerDialogState extends State<ClassPickerDialog> {
  ClassDesc? _selected;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClassDesc> get _filteredClasses {
    final classes = widget.registry.classes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (_searchQuery.isEmpty) return classes;

    return classes
        .where((cls) => cls.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredClasses = _filteredClasses;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Select Class",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search classes...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class List
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: filteredClasses.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No classes found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: filteredClasses.length,
                        itemBuilder: (context, index) {
                          final cls = filteredClasses[index];
                          final isSelected = _selected == cls;

                          return InkWell(
                            onTap: () => setState(() => _selected = cls),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: theme.colorScheme.outline.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 20,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cls.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Details Panel
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: _selected == null
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a class to view details',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                          : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Class Name
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.class_,
                                    size: 16,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selected!.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Superclass
                            _buildInfoRow(
                              theme,
                              icon: Icons.arrow_upward,
                              label: 'Extends',
                              value: _selected!.superClass?.name ?? 'None',
                            ),

                            const SizedBox(height: 20),

                            // Properties
                            _buildSectionHeader(theme, 'Properties', Icons.data_object),
                            const SizedBox(height: 8),
                            if (_selected!.properties.values.where((p) => !p.isMethod()).isEmpty)
                              _buildEmptyState(theme, 'No properties')
                            else
                              ..._selected!.properties.values
                                  .where((p) => !p.isMethod())
                                  .map((prop) => _buildPropertyItem(theme, prop)),

                            const SizedBox(height: 20),

                            // Methods
                            _buildSectionHeader(theme, 'Methods', Icons.functions),
                            const SizedBox(height: 8),
                            if (_selected!.properties.values.where((p) => p.isMethod()).isEmpty)
                              _buildEmptyState(theme, 'No methods')
                            else
                              ..._selected!.properties.values
                                  .where((p) => p.isMethod())
                                  .map((prop) => _buildMethodItem(theme, prop as MethodDesc)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _selected != null
                      ? () => Navigator.pop(context, _selected)
                      : null,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Select"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyItem(ThemeData theme, ClassPropertyDesc prop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                children: [
                  TextSpan(
                    text: prop.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: ': ',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: prop.type.name,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem(ThemeData theme, MethodDesc method) {
    final params = method.parameters.map((p) => p.name).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                children: [
                  TextSpan(
                    text: method.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: '($params)',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: ': ',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: method.type.name,
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}


class ClassSelector extends StatefulWidget {
  final ClassRegistry registry;
  final ClassDesc? initial;
  final ValueChanged<ClassDesc?>? onChanged;

  const ClassSelector({
    super.key,
    required this.registry,
    this.initial,
    this.onChanged,
  });

  @override
  State<ClassSelector> createState() => _ClassSelectorState();
}

class _ClassSelectorState extends State<ClassSelector> {
  ClassDesc? _selected;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  Future<void> _pickClass() async {
    final selected = await showDialog<ClassDesc>(
      context: context,
      builder: (_) => ClassPickerDialog(registry: widget.registry),
    );

    if (selected != null) {
      setState(() => _selected = selected);
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = _selected != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: _pickClass,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovering
                ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border.all(
              color: _isHovering
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasSelection
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  hasSelection ? Icons.class_ : Icons.search,
                  size: 16,
                  color: hasSelection
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selected?.name ?? "Select a class...",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasSelection
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: hasSelection ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: _isHovering
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}