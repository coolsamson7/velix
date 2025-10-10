import 'package:flutter/material.dart' hide Autocomplete;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/editor/editor.dart';

import '../../actions/action_parser.dart';
import '../../actions/autocomplete.dart';
import '../../actions/infer_types.dart';
import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class CodeEditorBuilder extends PropertyEditorBuilder<Code> {
  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return CodeEditor(
      value: value ?? "",
      onChanged: onChanged,
    );
  }
}

class Code {}

class CodeEditor extends StatefulWidget {
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const CodeEditor({super.key, required this.value, required this.onChanged});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class CompletionItem {
  final String label;
  final IconData? icon;

  CompletionItem({required this.label, required this.icon});
}

/// Parsing state: invalid, prefix-only (in progress), or complete
enum ParseState { invalid, prefixOnly, complete }

class _CodeEditorState extends State<CodeEditor> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<CompletionItem> _matches = [];
  int _selectedIndex = -1;
  bool _isUpdatingCompletion = false;

  String _lastUserText = '';
  int _lastUserCursorPos = 0;

  late Autocomplete autocomplete;
  TypeChecker? typeChecker;
  ParseState _parseState = ParseState.invalid;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  ParseResult lastResult = ParseResult.success(null, complete: false);

  ParseState checkParse(String input) {
    lastResult = ActionParser.instance.parseStrict(input, typeChecker: typeChecker);

    if (lastResult.complete)
      return ParseState.complete;

    lastResult = ActionParser.instance.parsePrefix(input, typeChecker: typeChecker);

    if (lastResult.success)
      return ParseState.prefixOnly;
    else
      return ParseState.invalid;
  }

  Iterable<CompletionItem> suggestions(String pattern, int offset) {
    try {
      return autocomplete
          .suggest(pattern, cursorOffset: offset)
          .map((suggestion) => CompletionItem(
        label: suggestion.suggestion,
        icon: suggestion.type == "field"
            ? Icons.data_object
            : Icons.functions,
      ));
    } catch (e) {
      return [];
    }
  }

  void _onTextChanged() {
    if (_isUpdatingCompletion) return;

    final sel = _controller.selection;
    final cursorPos = sel.baseOffset;

    if (cursorPos < 0) {
      _clearMatches();
      return;
    }

    final currentText = _controller.text;
    final hasInlineCompletion = sel.extentOffset > sel.baseOffset;

    // Extract user text (without inline completion)
    String userText;
    int userCursorPos;

    if (hasInlineCompletion) {
      // User text = everything before cursor + everything after selection
      userText = currentText.substring(0, sel.baseOffset) + currentText.substring(sel.extentOffset);
      userCursorPos = sel.baseOffset;
    } else {
      userText = currentText;
      userCursorPos = cursorPos;
    }

    // Only process if user text actually changed
    if (userText == _lastUserText && userCursorPos == _lastUserCursorPos) {
      return;
    }

    _lastUserText = userText;
    _lastUserCursorPos = userCursorPos;

    // Notify parent
    if (widget.value != userText) {
      widget.onChanged(userText);
    }

    // Get suggestions
    final matches = suggestions(userText, userCursorPos).toList();
    final state = checkParse(userText);

    setState(() {
      _matches = matches;
      _selectedIndex = matches.isNotEmpty ? 0 : -1;
      _parseState = state;
    });

    if (_matches.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay(_matches);
      _updateInlineCompletion();
    } else {
      _removeOverlay();
    }
  }

  void _updateInlineCompletion() {
    if (_isUpdatingCompletion) return;
    if (_matches.isEmpty || _selectedIndex < 0) return;

    final completion = _matches[_selectedIndex].label;
    final text = _lastUserText;
    final cursorPos = _lastUserCursorPos;

    if (cursorPos < 0 || cursorPos > text.length) return;

    // Use parse tree to find token boundaries
    final context = autocomplete.getCompletionContext(text, cursorPos);

    if (context == null) {
      // Fallback to old word-finding logic if parse fails
      int wordStart = cursorPos;
      while (wordStart > 0 && _isWordChar(text[wordStart - 1])) {
        wordStart--;
      }
      final typedPart = text.substring(wordStart, cursorPos);

      if (!completion.toLowerCase().startsWith(typedPart.toLowerCase()) ||
          completion.length == typedPart.length) {
        return;
      }

      final suffix = completion.substring(typedPart.length);
      final newText = text.substring(0, wordStart) + completion + text.substring(cursorPos);

      _isUpdatingCompletion = true;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: cursorPos,
          extentOffset: cursorPos + suffix.length,
        ),
      );
      Future.microtask(() {
        if (mounted) {
          _isUpdatingCompletion = false;
        }
      });
      return;
    }

    // Use parse tree token boundaries
    final tokenStart = context.tokenStart;
    final typedPart = text.substring(tokenStart, cursorPos);

    if (!completion.toLowerCase().startsWith(typedPart.toLowerCase()) ||
        completion.length == typedPart.length) {
      return;
    }

    final suffix = completion.substring(typedPart.length);
    final newText = text.substring(0, tokenStart) + completion + text.substring(cursorPos);

    _isUpdatingCompletion = true;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: cursorPos,
        extentOffset: cursorPos + suffix.length,
      ),
    );
    Future.microtask(() {
      if (mounted) {
        _isUpdatingCompletion = false;
      }
    });
  }

  void _selectNext() {
    if (_matches.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _matches.length;
    });
    _applyInlineCompletion();
  }

  void _selectPrevious() {
    if (_matches.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + _matches.length) % _matches.length;
    });
    _applyInlineCompletion();
  }

  void _applyInlineCompletion() {
    if (_isUpdatingCompletion) return;
    if (_matches.isEmpty || _selectedIndex < 0) return;

    final completion = _matches[_selectedIndex].label;
    final text = _lastUserText;
    final cursorPos = _lastUserCursorPos;

    if (cursorPos < 0 || cursorPos > text.length) return;

    int wordStart = cursorPos;
    while (wordStart > 0 && _isWordChar(text[wordStart - 1])) {
      wordStart--;
    }

    final typedPart = text.substring(wordStart, cursorPos);

    if (!completion.toLowerCase().startsWith(typedPart.toLowerCase())) {
      return;
    }

    if (completion.length == typedPart.length) {
      return;
    }

    final suffix = completion.substring(typedPart.length);
    final newText = text.substring(0, wordStart) + completion + text.substring(cursorPos);

    _isUpdatingCompletion = true;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: cursorPos,
        extentOffset: cursorPos + suffix.length,
      ),
    );
    Future.microtask(() {
      if (mounted) {
        _isUpdatingCompletion = false;
      }
    });
  }

  bool _isWordChar(String char) => RegExp(r'[a-zA-Z0-9_]').hasMatch(char);

  void _acceptCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) return;

    final selection = _controller.selection;
    if (selection.extentOffset > selection.baseOffset) {
      final acceptedText = _controller.text;
      final newCursorPos = selection.extentOffset;

      _isUpdatingCompletion = true;

      // Update internal state first
      _lastUserText = acceptedText;
      _lastUserCursorPos = newCursorPos;

      // Then update controller
      _controller.value = TextEditingValue(
        text: acceptedText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );

      Future.microtask(() {
        if (mounted) {
          _isUpdatingCompletion = false;
        }
      });
    }

    _clearMatches();
  }

  void _dismissCompletion() {
    final sel = _controller.selection;
    final hasSelection = sel.extentOffset > sel.baseOffset;

    if (hasSelection) {
      _isUpdatingCompletion = true;
      _controller.value = TextEditingValue(
        text: _lastUserText,
        selection: TextSelection.collapsed(offset: _lastUserCursorPos),
      );
      Future.microtask(() {
        if (mounted) {
          _isUpdatingCompletion = false;
        }
      });
    }

    _clearMatches();
  }

  void _clearMatches() {
    _removeOverlay();
    if (_matches.isNotEmpty) {
      setState(() {
        _matches = [];
        _selectedIndex = -1;
      });
    }
  }

  void _showOverlay(List<CompletionItem> items) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == _selectedIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _applyInlineCompletion();
                      _acceptCompletion();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: Row(
                        children: [
                          Icon(
                            item.icon ?? Icons.code,
                            size: 16,
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.blue.shade800
                                    : Colors.black87,
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
                  );
                },
              ),
            ),
          ),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final overlay = Overlay.of(context, rootOverlay: true);
        if (overlay != null) {
          overlay.insert(_overlayEntry!);
        }
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildStatusIndicator(bool hasFocus) {
    Color color;
    String message;

    switch (_parseState) {
      case ParseState.complete:
        color = Colors.green.shade800;
        message = "Code is valid";
        break;
      case ParseState.prefixOnly:
        color = hasFocus ? Colors.amber.shade700 : Colors.red.shade800;
        message = hasFocus
            ? "Code incomplete (valid prefix)"
            : "Incomplete code";
        break;
      case ParseState.invalid:
        color = Colors.red.shade800;
        message = "Parse error: ${lastResult.message ?? ""}";
        break;
    }

    return Positioned(
      top: 4,
      right: 4,
      bottom: 4,
      child: Tooltip(
        message: message,
        preferBelow: false,
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(_pulseAnimation.value), color],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value && !_isUpdatingCompletion) {
      final newValue = widget.value ?? '';
      if (newValue != _lastUserText) {
        _lastUserText = newValue;
        _lastUserCursorPos = newValue.length;
        _controller.text = newValue;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var editContext = Provider.of<EditContext>(context);

    typeChecker = TypeChecker(ClassDescTypeResolver(root: editContext.type!));
    autocomplete = Autocomplete(typeChecker: typeChecker!);
  }

  @override
  void initState() {
    super.initState();

    final initialValue = widget.value ?? '';
    _controller = TextEditingController(text: initialValue);
    _focusNode = FocusNode();
    _lastUserText = initialValue;
    _lastUserCursorPos = initialValue.length;

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
        if (_parseState == ParseState.prefixOnly) {
          setState(() {
            _parseState = ParseState.invalid;
          });
        }
      }
    });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _parseState = checkParse(initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _removeOverlay();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        if (_matches.isNotEmpty) {
          final sel = _controller.selection;
          final hasSelection = sel.extentOffset > sel.baseOffset;

          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowDown:
              _selectNext();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowUp:
              _selectPrevious();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.tab:
            case LogicalKeyboardKey.enter:
              _acceptCompletion();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              if (hasSelection) {
                _acceptCompletion();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            case LogicalKeyboardKey.escape:
              _dismissCompletion();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.backspace:
              if (hasSelection) {
                _dismissCompletion();
                return KeyEventResult.handled;
              }
              _clearMatches();
              return KeyEventResult.ignored;
            case LogicalKeyboardKey.arrowLeft:
              if (hasSelection) {
                _dismissCompletion();
                return KeyEventResult.handled;
              }
              _clearMatches();
              return KeyEventResult.ignored;
          }
        }

        return KeyEventResult.ignored;
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Stack(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: "Type here for autocompletion...",
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),
            _buildStatusIndicator(_focusNode.hasFocus),
          ],
        ),
      ),
    );
  }
}