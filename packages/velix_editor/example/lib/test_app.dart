import 'dart:async';
import 'package:flutter/material.dart' hide Autocomplete;
import 'package:flutter/services.dart';
import 'package:expressions/expressions.dart';
import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/actions/autocomplete.dart';

final pageClass = ClassDesc('Page',
    properties: {
      'user': FieldDesc('user', type: userClass),
    }
);

final userClass = ClassDesc('User',
  properties: {
    'name': FieldDesc('value', type: Desc.string_type),
    'address': FieldDesc('address',  type: addressClass),
    'hello': MethodDesc('hello', [Desc.string_type], type: Desc.string_type)
  },
);

final addressClass = ClassDesc('Address',
  properties: {
    'city': FieldDesc('city', type: Desc.string_type),
    'street': FieldDesc('street', type: Desc.string_type)
  },
);

var autocomplete = Autocomplete(pageClass);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Dot-Access Expression Editor')),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: IDEAutocompleteInline(options: []),
        ),
      ),
    );
  }
}


class IDEAutocompleteInline extends StatefulWidget {
  final List<CompletionItem> options;

  const IDEAutocompleteInline({super.key, required this.options});

  @override
  State<IDEAutocompleteInline> createState() => _IDEAutocompleteInlineState();
}

class CompletionItem {
  final String label;
  final IconData? icon;

  CompletionItem({required this.label, required this.icon});
}

class _IDEAutocompleteInlineState extends State<IDEAutocompleteInline> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<CompletionItem> _matches = [];
  int _selectedIndex = 0;
  bool _isUpdatingCompletion = false; // Prevent infinite loops

  Iterable<CompletionItem> suggestions(String pattern, int offset) {
    try {
      return autocomplete.suggest(pattern, cursorOffset: offset).map((str) => CompletionItem(label: str, icon: Icons.lightbulb_outline));
    }
    catch (e) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Prevent infinite loops when we're programmatically updating the text
    if (_isUpdatingCompletion) return;

    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos < 0) return;

    final matches = suggestions(_controller.text, cursorPos).toList();

    setState(() {
      _matches = matches;
      _selectedIndex = matches.isNotEmpty ? 0 : -1;
    });
  }

  void _acceptCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) return;

    _isUpdatingCompletion = true;

    final cursorPos = _controller.selection.baseOffset;
    final completion = _matches[_selectedIndex].label;

    // Find word start
    int wordStart = cursorPos;
    while (wordStart > 0 && _isWordChar(_controller.text[wordStart - 1])) {
      wordStart--;
    }

    final beforeWord = _controller.text.substring(0, wordStart);
    final afterCursor = _controller.text.substring(cursorPos);
    final newText = beforeWord + completion + afterCursor;
    final newCursorPos = wordStart + completion.length;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    setState(() {
      _matches = [];
      _selectedIndex = -1;
    });

    _isUpdatingCompletion = false;
  }

  bool _isWordChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  void _selectNext() {
    if (_matches.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _matches.length;
    });
  }

  void _selectPrevious() {
    if (_matches.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + _matches.length) % _matches.length;
    });
  }

  void _dismissCompletion() {
    setState(() {
      _matches = [];
      _selectedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        if (_matches.isNotEmpty) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowDown:
              _selectNext();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowUp:
              _selectPrevious();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.tab:
            case LogicalKeyboardKey.enter:
            case LogicalKeyboardKey.arrowRight:
              _acceptCompletion();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.escape:
              _dismissCompletion();
              return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean TextField
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: "Type here for autocompletion...",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
          ),

          // Elegant completion dropdown
          if (_matches.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _matches.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final item = _matches[index];
                    final isSelected = index == _selectedIndex;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                          _acceptCompletion();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon ?? Icons.code,
                                size: 20,
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.keyboard_return,
                                  size: 16,
                                  color: Colors.blue.shade400,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Helpful hint
          if (_matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Use ↑↓ to navigate • Tab/Enter/→ to accept • Esc to cancel',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}