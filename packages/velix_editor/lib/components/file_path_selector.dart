import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePathSelector extends StatefulWidget {
  final String? initialFilePath;
  final List<String>? recentFiles;
  final ValueChanged<String> onLoad;

  const FilePathSelector({
    super.key,
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
        }
      });
    }
  }

  void _selectRecent(String path) {
    setState(() {
      _controller.text = path;
    });
  }

  void _load() {
    final path = _controller.text;
    if (path.isNotEmpty) {
      widget.onLoad(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // File path display
        Expanded(
          child: TextFormField(
            controller: _controller,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "File",
              hintText: "No file selected",
            ),
          ),
        ),

        // Dropdown for recent + browse
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          tooltip: "Recent / Browse",
          onSelected: (value) {
            if (value == "__browse__") {
              _browseFile();
            } else {
              _selectRecent(value);
            }
          },
          itemBuilder: (context) {
            return [
              ..._recentFiles.map((f) => PopupMenuItem(
                value: f,
                child: Text(f),
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: "__browse__",
                child: Row(
                  children: [Icon(Icons.folder_open), SizedBox(width: 8), Text("Browse...")],
                ),
              ),
            ];
          },
        ),

        const SizedBox(width: 8),

        ElevatedButton(
          onPressed: _load,
          child: const Text("Load"),
        ),
      ],
    );
  }
}
