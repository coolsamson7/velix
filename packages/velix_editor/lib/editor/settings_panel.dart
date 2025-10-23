import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../components/class_picker.dart';
import '../components/file_path_selector.dart';
import 'editor.dart';

class SettingsPanel extends StatefulWidget {
  final EditorScreenState editor;

  const SettingsPanel({super.key, required this.editor});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  // override

  Future<String?> onLoadMetaData(String path) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final newPath = result.files.single.path!;
      widget.editor.loadRegistry(newPath);
      setState(() => {});
      return newPath;
    }

    return null;
  }

  Future<String?> onLoadFile(String path) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final newPath = result.files.single.path!;
      widget.editor.loadFile(newPath);
      setState(() => {});
      return newPath;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilePathSelector(
              title: "Meta Data",
              recentFiles: widget.editor.registryPaths,
              initialFilePath: widget.editor.registryPath,
              onLoad: onLoadMetaData,
            ),
            const SizedBox(height: 8),
            FilePathSelector(
              title: "File",
              recentFiles: widget.editor.paths,
              initialFilePath: widget.editor.path,
              onLoad: onLoadFile,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Main Class",
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    )
                  ),
                  const SizedBox(height: 8),
                  ClassSelector(
                    registry: widget.editor.registry,
                    initial: widget.editor.clazz,
                    onChanged: (clazz) => widget.editor.selectClass(clazz),
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
