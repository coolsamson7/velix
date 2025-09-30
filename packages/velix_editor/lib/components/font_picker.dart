import 'package:flutter/material.dart';

class FontPicker extends StatefulWidget {
  final String? selectedFont;
  final ValueChanged<String> onFontSelected;
  final List<String> availableFonts;
  final String previewText;
  final double previewFontSize;

  const FontPicker({
    super.key,
    this.selectedFont,
    required this.onFontSelected,
    required this.availableFonts,
    this.previewText = 'The quick brown fox jumps over the lazy dog',
    this.previewFontSize = 16,
  });

  @override
  State<FontPicker> createState() => _FontPickerState();
}

class _FontPickerState extends State<FontPicker> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get filteredFonts {
    if (_searchQuery.isEmpty) {
      return widget.availableFonts;
    }
    return widget.availableFonts
        .where((font) => font.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search fonts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        // Font list
        Expanded(
          child: filteredFonts.isEmpty
              ? Center(
            child: Text(
              'No fonts found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
              : ListView.builder(
            itemCount: filteredFonts.length,
            itemBuilder: (context, index) {
              final font = filteredFonts[index];
              final isSelected = font == widget.selectedFont;

              return InkWell(
                onTap: () => widget.onFontSelected(font),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : null,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              font,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.previewText,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: widget.previewFontSize,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Dropdown version for more compact usage
class FontPickerDropdown extends StatelessWidget {
  final String? selectedFont;
  final ValueChanged<String?> onFontSelected;
  final List<String> availableFonts;
  final String? hint;

  const FontPickerDropdown({
    super.key,
    this.selectedFont,
    required this.onFontSelected,
    required this.availableFonts,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedFont,
      decoration: InputDecoration(
        labelText: 'Font Family',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      hint: hint != null ? Text(hint!) : null,
      items: availableFonts.map((font) {
        return DropdownMenuItem(
          value: font,
          child: Text(
            font,
            style: TextStyle(fontFamily: font),
          ),
        );
      }).toList(),
      onChanged: onFontSelected,
    );
  }
}

// Dialog version for full-screen picker
class FontPickerDialog extends StatelessWidget {
  final String? selectedFont;
  final ValueChanged<String> onFontSelected;
  final List<String> availableFonts;

  const FontPickerDialog({
    super.key,
    this.selectedFont,
    required this.onFontSelected,
    required this.availableFonts,
  });

  static Future<String?> show({
    required BuildContext context,
    String? selectedFont,
    required List<String> availableFonts,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 500,
          height: 600,
          child: Column(
            children: [
              AppBar(
                title: const Text('Select Font'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: FontPicker(
                  selectedFont: selectedFont,
                  availableFonts: availableFonts,
                  onFontSelected: (font) {
                    Navigator.pop(context, font);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            AppBar(
              title: const Text('Select Font'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: FontPicker(
                selectedFont: selectedFont,
                availableFonts: availableFonts,
                onFontSelected: (font) {
                  onFontSelected(font);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage widget
class FontPickerExample extends StatefulWidget {
  const FontPickerExample({super.key});

  @override
  State<FontPickerExample> createState() => _FontPickerExampleState();
}

class _FontPickerExampleState extends State<FontPickerExample> {
  String? selectedFont = 'Roboto';

  // Common Google Fonts / System fonts
  final List<String> availableFonts = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Oswald',
    'Raleway',
    'Ubuntu',
    'Merriweather',
    'Playfair Display',
    'Poppins',
    'Courier',
    'Georgia',
    'Times New Roman',
    'Arial',
    'Helvetica',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Picker Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview of selected font
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Font: ${selectedFont ?? "None"}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The quick brown fox jumps over the lazy dog',
                    style: TextStyle(
                      fontFamily: selectedFont,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Button to open dialog
            ElevatedButton.icon(
              onPressed: () async {
                final result = await FontPickerDialog.show(
                  context: context,
                  selectedFont: selectedFont,
                  availableFonts: availableFonts,
                );
                if (result != null) {
                  setState(() => selectedFont = result);
                }
              },
              icon: const Icon(Icons.font_download),
              label: const Text('Open Font Picker Dialog'),
            ),
            const SizedBox(height: 20),

            // Dropdown version
            FontPickerDropdown(
              selectedFont: selectedFont,
              availableFonts: availableFonts,
              hint: 'Select a font',
              onFontSelected: (font) {
                setState(() => selectedFont = font);
              },
            ),
            const SizedBox(height: 20),

            // Inline picker
            const Text(
              'Inline Font Picker:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FontPicker(
                selectedFont: selectedFont,
                availableFonts: availableFonts,
                onFontSelected: (font) {
                  setState(() => selectedFont = font);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}