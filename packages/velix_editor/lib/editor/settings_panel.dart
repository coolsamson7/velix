import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../components/class_picker.dart';
import '../components/file_path_selector.dart';
import 'editor.dart';

class SettingsPanel extends StatelessWidget {
  // instance data

  final EditorScreenState editor;

  // constructor

  const SettingsPanel({super.key, required this.editor});

  // internal

  Future<String?> onLoad(String path) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      var path = result.files.single.path!;

      await editor.loadRegistry(path);

      return result.files.single.path;
    }

    return null;
  }

  // override

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select File",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // The actual selector (stateful)
            FilePathSelector(
              recentFiles: [],
              initialFilePath: "",
              onLoad: (path) async {
                // Forward to your async callback
                await onLoad(path);
              },
            ),

            const Text(
              "Select Class",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ClassSelector(
              registry: editor.registry,
              initial: null,
              onChanged: (clazz) => print(clazz),
            )
          ],
        ),
      ),
    );
  }
}