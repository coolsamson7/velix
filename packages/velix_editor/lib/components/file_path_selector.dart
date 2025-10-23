import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FilePathSelector extends StatefulWidget {
  final String title;
  final String? initialFilePath;
  final List<String>? recentFiles;
  final ValueChanged<String> onLoad;

  const FilePathSelector({
    super.key,
    required this.title,
    this.initialFilePath,
    this.recentFiles,
    required this.onLoad,
  });

  @override
  State<FilePathSelector> createState() => _FilePathSelectorState();
}

class _FilePathSelectorState extends State<FilePathSelector> {
  late TextEditingController _controller;
  late List<String> _recentFiles;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFilePath ?? '');
    _recentFiles = widget.recentFiles ?? [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _browseFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path!;
      setState(() {
        _controller.text = path;
        if (!_recentFiles.contains(path)) {
          _recentFiles.insert(0, path);
          if (_recentFiles.length > 5) {
            _recentFiles = _recentFiles.sublist(0, 5);
          }
        }
      });
      widget.onLoad(path); // auto-load immediately
    }
  }

  void _selectRecent(String path) {
    setState(() {
      _controller.text = path;
    });
    widget.onLoad(path); // auto-load immediately
  }

  String _getFileName(String path) {
    if (path.isEmpty) return 'No file selected';
    return path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = _controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // File display area
          MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: InkWell(
              onTap: _browseFile,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isHovering
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isHovering
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasFile
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        hasFile ? Icons.description : Icons.folder_open,
                        size: 20,
                        color: hasFile
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFileName(_controller.text),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: hasFile
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: hasFile
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasFile) ...[
                            const SizedBox(height: 4),
                            Text(
                              _controller.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent files
          if (_recentFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Recent Files',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _recentFiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final file = _recentFiles[index];
                  final isSelected = _controller.text == file;

                  return InkWell(
                    onTap: () => _selectRecent(file),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 14,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getFileName(file),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
