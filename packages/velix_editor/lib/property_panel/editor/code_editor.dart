import 'package:flutter/material.dart' hide Autocomplete;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../../actions/autocomplete.dart';
import '../../actions/types.dart';
import '../../commands/command_stack.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class CodeEditorBuilder extends PropertyEditorBuilder<Code> {
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

class _CodeEditorState extends State<CodeEditor>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<CompletionItem> _matches = [];
  int _selectedIndex = 0;
  bool _isUpdatingCompletion = false;
  String _originalText = '';
  int _originalCursorPos = 0;
  late Autocomplete autocomplete;
  String? _parseException;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  Iterable<CompletionItem> suggestions(String pattern, int offset) {
    try {
      final suggestions = autocomplete
          .suggest(pattern, cursorOffset: offset)
          .map((suggestion) => CompletionItem(
          label: suggestion.suggestion,
          icon: suggestion.type == "field"
              ? Icons.data_object
              : Icons.functions));

      // Clear parse exception if suggestions work
      if (_parseException != null) {
        setState(() {
          _parseException = null;
        });
        // Stop pulse animation when error is cleared
        _pulseController.stop();
      }

      return suggestions;
    } catch (e) {
      // Update parse exception state
      if (_parseException != e.toString()) {
        setState(() {
          _parseException = e.toString();
        });
        // Start pulse animation for errors
        _pulseController.repeat(reverse: true);
      }

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

    _originalText = _controller.text;
    _originalCursorPos = cursorPos;

    final matches = suggestions(_controller.text, cursorPos).toList();

    if ( widget.value != _originalText)
      widget.onChanged(_originalText);

    setState(() {
      _matches = matches;
      _selectedIndex = matches.isNotEmpty ? 0 : -1;
    });

    if (_matches.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }

    _updateInlineCompletion();
  }

  void _updateInlineCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) {
      return;
    }

    final completion = _matches[_selectedIndex].label;

    int wordStart = _originalCursorPos;
    while (wordStart > 0 && _isWordChar(_originalText[wordStart - 1])) {
      wordStart--;
    }

    final typedPart = _originalText.substring(wordStart, _originalCursorPos);

    // Only update if completion extends the typedPart and cursor hasn't moved left
    if (!completion.toLowerCase().startsWith(typedPart.toLowerCase()) ||
        completion.length <= typedPart.length) {
      return; // User probably deleted or moved cursor back, don't autocomplete
    }

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



  bool _isWordChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  void _acceptCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) return;

    final selection = _controller.selection;
    if (selection.extentOffset > selection.baseOffset) {
      _isUpdatingCompletion = true;
      _controller.selection = TextSelection.collapsed(offset: selection.extentOffset);
      _isUpdatingCompletion = false;
    }

    _removeOverlay();

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

    _isUpdatingCompletion = true;
    _controller.value = TextEditingValue(
      text: _originalText,
      selection: TextSelection.collapsed(offset: _originalCursorPos),
    );
    _isUpdatingCompletion = false;

    _removeOverlay();

    setState(() {
      _matches = [];
      _selectedIndex = -1;
    });
  }

  void _showOverlay() {
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
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final item = _matches[index];
                  final isSelected = index == _selectedIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _updateInlineCompletion();
                      _acceptCompletion();
                    },
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: isSelected ? Colors.blue.shade50 : null,
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
                                fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.normal,
                                color:
                                isSelected ? Colors.blue.shade800 : Colors.black87,
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

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildStatusIndicator() {
    return Positioned(
      top: 4,
      right: 4,
      bottom: 4,
      child: Tooltip(
        message: _parseException == null
            ? "Code is valid"
            : "Parse error: $_parseException",
        preferBelow: false,
        textStyle: const TextStyle(fontSize: 12),
        decoration: BoxDecoration(
          color: _parseException == null
              ? Colors.green.shade800
              : Colors.red.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: _parseException == null
                    ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.shade400, Colors.green.shade600],
                )
                    : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.shade400.withOpacity(_pulseAnimation.value),
                    Colors.red.shade600.withOpacity(_pulseAnimation.value),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    autocomplete = Autocomplete(Provider.of<ClassDesc>(context));
  }

  @override
  void didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value.toString() != _controller.text) {
      // Update controller text if external value has changed
      _controller.text = widget.value.toString();
    }
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
      }
    });

    // Initialize pulse animation for error states
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
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
              final sel = _controller.selection;
              // 🚀 Only accept if selection highlights suggestion
              if (sel.extentOffset > sel.baseOffset) {
                _acceptCompletion();
                return KeyEventResult.handled;
              }
              // else: let cursor move right normally
              return KeyEventResult.ignored;

            case LogicalKeyboardKey.escape:
              _dismissCompletion();
              return KeyEventResult.handled;

            case LogicalKeyboardKey.backspace:
            case LogicalKeyboardKey.arrowLeft:
              _dismissCompletion();
              return KeyEventResult.handled;
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _buildStatusIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}