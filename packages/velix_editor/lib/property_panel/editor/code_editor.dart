import 'package:flutter/material.dart' hide Autocomplete;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/editor/editor.dart';
import 'package:velix_editor/metadata/widgets/dropdown.dart';
import 'package:velix_editor/metadata/widgets/for.dart';

import '../../actions/action_parser.dart';
import '../../actions/autocomplete.dart';
import '../../actions/infer_types.dart';
import '../../actions/types.dart';
import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../metadata/widget_data.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class CodeEditorBuilder extends PropertyEditorBuilder<Code> {
  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required WidgetData widget,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return CodeEditor(
      widget: widget,
      object: object,
      property: property,
      value: value ?? "",
      onChanged: onChanged,
    );
  }
}

class Code {}

class CodeEditor extends StatefulWidget {
  final WidgetData widget;
  final dynamic object;
  final PropertyDescriptor property;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const CodeEditor({
    super.key,
    required this.widget,
    required this.object,
    required this.property,
    required this.value,
    required this.onChanged,
  });

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

  // NEW inline completion tracking
  bool _hasInlineCompletion = false;
  int _inlineSuffixLength = 0;
  int _inlineWordStart = 0;

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
      return _parseState = ParseState.complete;

    if (input.isEmpty) {
      lastResult.success = true;
      lastResult.complete = true;

      return _parseState = ParseState.complete;
    }
    else {
      lastResult = ActionParser.instance.parsePrefix(input, typeChecker: typeChecker);

      return _parseState = lastResult.success ? ParseState.prefixOnly : ParseState.invalid;
    }


  }

  Iterable<CompletionItem> suggestions(String pattern, int offset) {
    try {
      return autocomplete
          .suggest(pattern, cursorOffset: offset)
          .map((s) => CompletionItem(
        label: s.suggestion,
        icon: s.type == "field" ? Icons.data_object : Icons.functions,
      ));
    } catch (_) {
      return [];
    }
  }

  void changed(String text) {
    if (widget.value != text) {
      widget.onChanged(text);
    }

    checkParse(text);
  }

  void _onTextChanged() {
    if (_isUpdatingCompletion) return;

    final sel = _controller.selection;
    if (!sel.isValid) {
      _clearMatches();
      return;
    }

    final userText = sel.baseOffset <= sel.extentOffset
        ? _controller.text.substring(0, sel.baseOffset) +
        _controller.text.substring(sel.extentOffset)
        : _controller.text;

    final userCursorPos = sel.baseOffset.clamp(0, userText.length);

    if (userText == _lastUserText && userCursorPos == _lastUserCursorPos) return;

    _lastUserText = userText;
    _lastUserCursorPos = userCursorPos;

    changed(userText);

    final matches = suggestions(userText, userCursorPos).toList();

    setState(() {
      _matches = matches;
      _selectedIndex = matches.isNotEmpty ? 0 : -1;
    });

    if (_matches.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay(_matches);
      _updateInlineCompletionNormalized(userText, userCursorPos);
    } else {
      _removeOverlay();
    }
  }

  void _updateInlineCompletionNormalized(String userText, int cursorPos) {
    if (_isUpdatingCompletion || _matches.isEmpty || _selectedIndex < 0) return;

    final completion = _matches[_selectedIndex].label;
    int wordStart = cursorPos;
    while (wordStart > 0 && _isWordChar(userText[wordStart - 1])) {
      wordStart--;
    }

    final typedPart = userText.substring(wordStart, cursorPos);

    if (!completion.toLowerCase().startsWith(typedPart.toLowerCase()) ||
        completion.length == typedPart.length) {
      _hasInlineCompletion = false;
      _inlineSuffixLength = 0;
      _inlineWordStart = 0;
      return;
    }

    final suffix = completion.substring(typedPart.length);
    final newText = userText.substring(0, wordStart) + completion + userText.substring(cursorPos);

    _hasInlineCompletion = true;
    _inlineSuffixLength = suffix.length;
    _inlineWordStart = wordStart;

    _isUpdatingCompletion = true;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: cursorPos,
        extentOffset: cursorPos + suffix.length,
      ),
    );

    Future.microtask(() {
      if (mounted) _isUpdatingCompletion = false;
    });
  }

  bool _isWordChar(String char) => RegExp(r'[a-zA-Z0-9_]').hasMatch(char);

  void _acceptCompletion() {
    if (_matches.isEmpty || _selectedIndex < 0) return;

    final userText = _lastUserText;
    final cursorPos = _lastUserCursorPos;
    final completion = _matches[_selectedIndex].label;

    int wordStart = cursorPos;
    while (wordStart > 0 && _isWordChar(userText[wordStart - 1])) {
      wordStart--;
    }

    final typedPart = userText.substring(wordStart, cursorPos);
    if (!completion.toLowerCase().startsWith(typedPart.toLowerCase()) ||
        completion.length == typedPart.length) {
      _clearMatches();
      return;
    }

    final newText = userText.substring(0, wordStart) + completion + userText.substring(cursorPos);
    final newCursorPos = wordStart + completion.length;

    changed(newText);

    _lastUserText = newText;
    _lastUserCursorPos = newCursorPos;

    _hasInlineCompletion = false;
    _inlineSuffixLength = 0;
    _inlineWordStart = 0;

    _isUpdatingCompletion = true;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    Future.microtask(() {
      if (mounted) _isUpdatingCompletion = false;
    });

    _clearMatches();
  }

  void _dismissCompletion() {
    _hasInlineCompletion = false;
    _inlineSuffixLength = 0;
    _inlineWordStart = 0;

    _isUpdatingCompletion = true;

    _controller.value = TextEditingValue(
      text: _lastUserText,
      selection: TextSelection.collapsed(offset: _lastUserCursorPos),
    );

    Future.microtask(() {
      if (mounted) _isUpdatingCompletion = false;
    });

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
                      _acceptCompletion();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: Row(
                        children: [
                          Icon(item.icon ?? Icons.code,
                              size: 16,
                              color: isSelected
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.normal,
                                color: isSelected
                                    ? Colors.blue.shade800
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.keyboard_return,
                                size: 14, color: Colors.blue.shade400),
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
        overlay?.insert(_overlayEntry!);
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

    // WTF

    if (lastResult.success) {
      if (lastResult.complete)
        _parseState = ParseState.complete;
      else
        _parseState = ParseState.prefixOnly;
    }
    else {
      _parseState = ParseState.invalid;
    }

    //

    switch (_parseState) {
      case ParseState.complete:
        color = Colors.green.shade800;
        message = "Code is valid";
        break;
      case ParseState.prefixOnly:
        color = hasFocus ? Colors.amber.shade700 : Colors.red.shade800;
        message = hasFocus ? "Code incomplete (valid prefix)" : "Incomplete code";
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    var editContext = Provider.of<EditContext>(context);
    ClassDesc classContext = editContext.type!;
    Map<String,ClassDesc> variables = {};
    var resolver = ClassDescTypeResolver(root: classContext, variables: variables);
    typeChecker = TypeChecker(resolver);

    ClassDesc findContext() {
      ClassDesc findWidgetContext(WidgetData widget) {
        var parentContext =
        widget.parent != null ? findWidgetContext(widget.parent!) : editContext.type!;
        var result = parentContext;

        if (widget.type == "for") {
          var forWidget = widget as ForWidgetData;
          var pr = ActionParser.instance.parseStrict(forWidget.context, typeChecker: typeChecker);
          if (pr.success) {
            var type = pr.value!.getType<Desc>();
            if (type.isList()) {
              type = (type as ListDesc).elementType;
              resolver = ClassDescTypeResolver(root: type as ClassDesc, variables: variables);
              typeChecker = TypeChecker(resolver);
            }
          }
        }
        return result;
      }

      return findWidgetContext(widget.widget);
    }

    classContext = findContext();

    // TODO:just a test

    var property = widget.property;
    if ( property.name == "onSelect") {
      //variables["\$value"] = ClassDesc("kkk");

      var dropDown = widget.object as DropDownWidgetData;

      if (dropDown.children.isNotEmpty && dropDown.children[0].type == "for") {
        ForWidgetData forWidget = dropDown.children[0] as ForWidgetData;

        var binding = forWidget.context;

        if ( binding.isNotEmpty) {
          var parseResult = ActionParser.instance.parseStrict(binding, typeChecker: typeChecker);

          if ( parseResult.success && parseResult.complete) {
            var type = parseResult.value!.getType<Desc>();

            if ( type is ListDesc) {
              var elementType = type.elementType;

              ClassDescTypeResolver descResolver = typeChecker!.resolver as ClassDescTypeResolver;

              descResolver.variables["value"] = elementType;
            }
          }
        } // if
      } // if
    } // if

    autocomplete = Autocomplete(typeChecker: typeChecker!);
    _parseState = checkParse(widget.value ?? "");
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

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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

        if (_matches.isNotEmpty || _hasInlineCompletion) {
          final sel = _controller.selection;
          final hasSelection = sel.extentOffset > sel.baseOffset;

          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowDown:
              _selectedIndex = (_selectedIndex + 1) % _matches.length;
              _updateInlineCompletionNormalized(_lastUserText, _lastUserCursorPos);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowUp:
              _selectedIndex = (_selectedIndex - 1 + _matches.length) % _matches.length;
              _updateInlineCompletionNormalized(_lastUserText, _lastUserCursorPos);
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
              if (_hasInlineCompletion) {
                // accept inline completion immediately
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
