import 'dart:async';

import 'package:flutter/material.dart' hide Autocomplete;
import 'package:flutter/services.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import 'package:velix_ui/provider/environment_provider.dart';

import '../../actions/autocomplete.dart';
import '../../actions/parser.dart';
import '../../actions/types.dart';
import '../../commands/command_stack.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Dataclass()
class User {
  // instance data

  @Attribute()
  String name = "";

  // constructor

  User({required this.name});

  // methods

  @Inject()
  String hello(String message) {
    print("hello $message");
    return "hello $message";
  }
}


@Injectable()
@Dataclass()
class Page {
  // instance data

  @Attribute()
  final User user;

  // constructor

  Page() : user = User(name: "andi");

  // methods

  @Inject()
  void setup() {
    print("setup");
  }
}


// we currently need a dummy class so that it doesn't conflict with the real string editor :-(
class Code {}

@Injectable()
class CodeEditorBuilder extends PropertyEditorBuilder<Code> {
  // override

  @override
  Widget buildEditor({
    required MessageBus messageBus,
    required CommandStack commandStack,
    required FieldDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return CodeEditor(
      options: [],
      //label: label,
     // value: value ?? "",
      //onChanged: onChanged, TODO
    );
  }
}

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

class CodeEditor extends StatefulWidget {
  final List<CompletionItem> options;

  const CodeEditor({super.key, required this.options});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class CompletionItem {
  final String label;
  final IconData? icon;

  CompletionItem({required this.label, required this.icon});
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<CompletionItem> _matches = [];
  int _selectedIndex = 0;
  bool _isUpdatingCompletion = false;
  String _originalText = '';
  int _originalCursorPos = 0;

  Iterable<CompletionItem> suggestions(String pattern, int offset) {
    try {
      return autocomplete.suggest(pattern, cursorOffset: offset)
          .map((suggestion) => CompletionItem(
          label: suggestion.suggestion,
          icon: suggestion.type == "field" ? Icons.data_object : Icons.functions
      ));
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
    if (_isUpdatingCompletion) return;

    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos < 0) return;

    // Store the original state when user types
    _originalText = _controller.text;
    _originalCursorPos = cursorPos;

    final matches = suggestions(_controller.text, cursorPos).toList();

    setState(() {
      _matches = matches;
      _selectedIndex = matches.isNotEmpty ? 0 : -1;
    });

    _updateInlineCompletion();
  }

  void _updateInlineCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) {
      return;
    }

    final completion = _matches[_selectedIndex].label;

    // Find word start
    int wordStart = _originalCursorPos;
    while (wordStart > 0 && _isWordChar(_originalText[wordStart - 1])) {
      wordStart--;
    }

    final typedPart = _originalText.substring(wordStart, _originalCursorPos);

    if (completion.toLowerCase().startsWith(typedPart.toLowerCase())) {
      final beforeWord = _originalText.substring(0, wordStart);
      final afterCursor = _originalText.substring(_originalCursorPos);
      final newText = beforeWord + completion + afterCursor;

      _isUpdatingCompletion = true;

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: wordStart + typedPart.length,
          extentOffset: wordStart + completion.length,
        ),
      );

      _isUpdatingCompletion = false;
    }
  }

  bool _isWordChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  void _acceptCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) return;

    // Move cursor to end of completion
    final selection = _controller.selection;
    if (selection.extentOffset > selection.baseOffset) {
      _isUpdatingCompletion = true;
      _controller.selection = TextSelection.collapsed(offset: selection.extentOffset);
      _isUpdatingCompletion = false;
    }

    setState(() {
      _matches = [];
      _selectedIndex = -1;
    });
  }

  void _selectNext() {
    if (_matches.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _matches.length;
    });
    _updateInlineCompletion();
  }

  void _selectPrevious() {
    if (_matches.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + _matches.length) % _matches.length;
    });
    _updateInlineCompletion();
  }

  void _dismissCompletion() {
    if (_matches.isEmpty) return;

    // Restore original text and cursor position
    _isUpdatingCompletion = true;
    _controller.value = TextEditingValue(
      text: _originalText,
      selection: TextSelection.collapsed(offset: _originalCursorPos),
    );
    _isUpdatingCompletion = false;

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
          // TextField with inline completion
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

          // Compact suggestion list
          if (_matches.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(maxHeight: 150),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _matches.length,
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
                          _updateInlineCompletion();
                          _acceptCompletion();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon ?? Icons.code,
                                size: 16,
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.keyboard_return,
                                  size: 14,
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

          // Compact hint
          if (_matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '↑↓ navigate • Tab/Enter/→ accept • Esc cancel',
                style: TextStyle(
                  fontSize: 11,
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