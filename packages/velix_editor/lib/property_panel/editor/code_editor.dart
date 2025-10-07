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

  String _originalText = '';
  int _originalCursorPos = 0;

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

    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos < 0) {
      _removeOverlay();
      return;
    }

    // Only update original input when user types, not during completion navigation
    _originalText = _controller.text;
    _originalCursorPos = cursorPos;

    final matches = suggestions(_controller.text, cursorPos).toList();

    if (widget.value != _originalText) {
      widget.onChanged(_originalText);
    }

    final state = checkParse(_controller.text);

    setState(() {
      _matches = matches;
      _selectedIndex = matches.isNotEmpty ? 0 : -1;
      _parseState = state;
    });

    if (_matches.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay(_matches);
    } else {
      _removeOverlay();
    }

    // Inline completion only on new user input, not on navigation
    _updateInlineCompletion();
  }

  void _updateInlineCompletion() {
    if (_isUpdatingCompletion) return;
    if (_matches.isEmpty || _selectedIndex < 0) return;

    final completion = _matches[_selectedIndex].label;
    final text = _originalText;
    final cursorPos = _originalCursorPos;

    if (cursorPos < 0 || cursorPos > text.length) return;

    // find the start of the current word
    int wordStart = cursorPos;
    while (wordStart > 0 && _isWordChar(text[wordStart - 1])) {
      wordStart--;
    }

    final typedPart = text.substring(wordStart, cursorPos);

    if (!completion.toLowerCase().startsWith(typedPart.toLowerCase())
        || completion.length == typedPart.length) return;

    final suffix = completion.substring(typedPart.length);
    final newText = text.substring(0, wordStart) + completion + text.substring(cursorPos);

    _isUpdatingCompletion = true;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: cursorPos,    // keep cursor at end of typed part
        extentOffset: cursorPos + suffix.length, // select only suffix
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _isUpdatingCompletion = false);
  }

  /// Arrow key navigation always applies completion on top of last user input
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
    final text = _originalText;
    final cursorPos = _originalCursorPos;

    if (cursorPos < 0 || cursorPos > text.length) return;

    int wordStart = cursorPos;
    while (wordStart > 0 && _isWordChar(text[wordStart - 1])) {
      wordStart--;
    }

    final typedPart = text.substring(wordStart, cursorPos);

    if (!completion.toLowerCase().startsWith(typedPart.toLowerCase())
        || completion.length == typedPart.length) return;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _isUpdatingCompletion = false);
  }

  bool _isWordChar(String char) => RegExp(r'[a-zA-Z0-9_]').hasMatch(char);

  void _acceptCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) return;

    final selection = _controller.selection;
    if (selection.extentOffset > selection.baseOffset) {
      _isUpdatingCompletion = true;
      _controller.selection =
          TextSelection.collapsed(offset: selection.extentOffset);
      _isUpdatingCompletion = false;
    }

    _removeOverlay();

    setState(() {
      _matches = [];
      _selectedIndex = -1;
    });
  }

  void _dismissCompletion() {
    // Revert to user original if inline completion is active
    final sel = _controller.selection;
    final hasSelection = sel.extentOffset > sel.baseOffset;

    if (hasSelection && _matches.isNotEmpty) {
      _isUpdatingCompletion = true;
      _controller.value = TextEditingValue(
        text: _originalText,
        selection: TextSelection.collapsed(offset: _originalCursorPos),
      );
      _isUpdatingCompletion = false;
    }

    _removeOverlay();

    setState(() {
      _matches = [];
      _selectedIndex = -1;
    });
  }

  void _showOverlay(List<CompletionItem> items) {
    if (_overlayEntry != null) return;
    _removeOverlay();

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
      if (mounted && Overlay.of(context, rootOverlay: true) != null) {
        Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
      }
    });
  }

  void _removeOverlay() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
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
        textStyle: const TextStyle(fontSize: 12),
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

    // Only update the controller text if the value actually changed
    if (oldWidget.value != widget.value && !_isUpdatingCompletion) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var editContext = Provider.of<EditContext>(context);

    typeChecker = TypeChecker(ClassDescTypeResolver(root: editContext.type));
    autocomplete = Autocomplete(typeChecker: typeChecker!);
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
        // Downgrade prefixOnly → invalid when losing focus
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

    _parseState = checkParse(widget.value ?? "");
    _originalText = widget.value ?? '';
    _originalCursorPos = _controller.selection.baseOffset;
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
            // If there's an inline completion (selection), dismiss it and prevent backspace
              if (hasSelection) {
                _dismissCompletion();
                return KeyEventResult.handled;
              }
              // No selection – clear matches and allow backspace to delete normally
              setState(() {
                _matches = [];
                _selectedIndex = -1;
              });
              _removeOverlay();
              return KeyEventResult.ignored;
            case LogicalKeyboardKey.arrowLeft:
            // If cursor is within the inline completion (has selection), just dismiss it
            // Don't move cursor, just remove the suggestion
              if (hasSelection) {
                _dismissCompletion();
                return KeyEventResult.handled;
              }
              // No selection – allow normal arrow left behavior
              _dismissCompletion();
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