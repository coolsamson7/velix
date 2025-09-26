import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_di/di/di.dart';

import 'package:velix_ui/provider/environment_provider.dart';

import '../../actions/parser.dart';
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
  String hello() {
    return "world";
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
      //label: label,
     // value: value ?? "",
      onChanged: onChanged,
    );
  }
}

class CodeEditor extends StatefulWidget {
  // instance data

  final ValueChanged<dynamic> onChanged;

  // constructor

  const CodeEditor({super.key, required this.onChanged});

  // override

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}


class _CodeEditorState extends State<CodeEditor> {
  // instance data

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final LayerLink layerLink = LayerLink();

  List<String> suggestions = [];
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  String? error;
  int selectedSuggestionIndex = -1;

  late Environment environment;// = EnvironmentProvider.of(context);

  late TypeDescriptor typeDescriptor;

  final parser = ExpressionParser();

  // internal

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _showSuggestionsIfNeeded();
      }
    });
    _validateExpression(controller.text);
  }

  void _onFocusChanged() {
    if (!focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  String get _caretWord {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    if (offset <= 0) return '';

    int start = offset - 1;
    while (start > 0 && !" .\n()[]{}+\\-*/=<>!&|,".contains(text[start - 1])) {
      start--;
    }
    return text.substring(start, offset);
  }

  void _showSuggestionsIfNeeded() {
    final word = _caretWord;
    if (word.isEmpty) {
      _removeOverlay();
      return;
    }
    final s = _getSuggestions(word);
    if (s.isNotEmpty && focusNode.hasFocus) {
      setState(() {
        suggestions = s;
        selectedSuggestionIndex = 0;
        _showOverlay();
      });
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  final parts = suggestion.split('.');

                  var field = typeDescriptor.findField(parts[0]);
                  var referencedType = field != null ?  (field.type as ObjectType).typeDescriptor : null;

                  final isMethod = false;// TODO parts.length == 2 && referencedType != null &&  finreferencedType.getMethods().containsKey(parts[1]) == true;
                  final isSelected = index == selectedSuggestionIndex;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _insertSuggestion(suggestion),
                    child: Container(
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isMethod
                              ? Icons.functions
                              : (parts.length == 2
                              ? Icons.data_object
                              : Icons.class_),
                          size: 16,
                          color: isMethod
                              ? Colors.purple
                              : (parts.length == 2 ? Colors.blue : Colors.green),
                        ),
                        title: Text(
                          suggestion,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: isSelected ? Colors.blue.shade800 : null,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: _getSubtitle(suggestion),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget? _getSubtitle(String suggestion) {
    final parts = suggestion.split('.');
    if (parts.length == 2) {
      final className = parts[0];

      var descriptor = typeDescriptor.findField(className);
      if (descriptor != null) {
        final memberName = parts[1];

        var field = (descriptor.type as ObjectType).typeDescriptor.findField(memberName);


        if (field != null) {
          return Text(
            'Field: ${field.name}',
            style: const TextStyle(fontSize: 11),
          );
        }
      }
  }

    return null;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _insertSuggestion(String suggestion) {
    final text = controller.text;
    final caret = controller.selection.baseOffset;

    // Find start of word before caret
    int start = caret;
    while (start > 0 && !" .\n()[]{}+\\-*/=<>!&|,".contains(text[start - 1])) {
      start--;
    }
    final word = text.substring(start, caret);

    // If the 'word' is a partial like "Car." or "Car.b", find the last dot
    int dotIndex = word.lastIndexOf('.');
    String prefix = '';
    if (dotIndex >= 0) {
      // The prefix includes the class, e.g. "Car."
      prefix = word.substring(0, dotIndex + 1);
    }

    // If user's input already matches the suggestion's prefix, insert only the remaining part
    String suggestionToInsert;
    if (suggestion.startsWith(prefix)) {
      suggestionToInsert = suggestion.substring(prefix.length);
    } else {
      // Fallback: insert the full suggestion
      suggestionToInsert = suggestion;
    }

    final before = text.substring(0, start + prefix.length);
    final after = text.substring(caret);

    controller.value = TextEditingValue(
      text: before + suggestionToInsert + after,
      selection: TextSelection.collapsed(offset: before.length + suggestionToInsert.length),
    );

    _removeOverlay();
    focusNode.requestFocus();
    _validateExpression(controller.text);
  }


  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && suggestions.isNotEmpty && focusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          selectedSuggestionIndex =
              (selectedSuggestionIndex + 1) % suggestions.length;
          _showOverlay();
        });
      }
      else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          selectedSuggestionIndex =
              (selectedSuggestionIndex - 1 + suggestions.length) %
                  suggestions.length;
          _showOverlay();
        });
      }
      else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        if (selectedSuggestionIndex >= 0) {
          _insertSuggestion(suggestions[selectedSuggestionIndex]);
        }
      }
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeOverlay();
      }
    }
  }

  void _validateExpression(String input) {
    if (input.trim().isEmpty) {
      setState(() => error = null);
      return;
    }

    try {
      final expression = parser.expression.parse(input);
      print(expression);
      /*final evaluator = const MyEvaluator();

      final context = <String, dynamic>{};
      for (final entry in sampleData.entries) {
        final className = entry.key;
        final classInstance = entry.value as Map<String, dynamic>;
        context[className] = classInstance;
        for (final member in classInstance.entries) {
          context['$className.${member.key}'] = member.value;
        }
      }

      final result = evaluator.eval(expression, context);*/
      var result = "ok";
      setState(() => error = 'Result: $result');
    } catch (e) {
      setState(() => error = 'Error: $e');
    }
  }

  List<String> _getSuggestions(String pattern) {
    if (pattern.contains('.')) {
      final parts = pattern.split('.');
      if (parts.length == 2) {
        final className = parts[0];
        final partial = parts[1];

        var field = typeDescriptor.findField(className);

        if (field == null)
          return [];

        var referencedType = (field.type as ObjectType).typeDescriptor;

        final suggestions = <String>[];

        // fields

        for (var f in referencedType.getFieldNames()) {
          if (f.startsWith(partial)) {
            suggestions.add('$className.$f');
          }
        }

        // methods

        for (var m in referencedType.getMethods()) {
          if (m.name.startsWith(partial)) {
            suggestions.add('$className.${m.name}');
          }
        }
        return suggestions;
      }
    }
    else {
      return typeDescriptor.getFieldNames().where((c) => c.startsWith(pattern)).toList();
    }
    return [];
  }


  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    typeDescriptor = TypeDescriptor.forType<Page>();
  }

  @override
  void initState() {
    super.initState();

    controller.addListener(_onTextChanged);
    focusNode.addListener(_onFocusChanged);

    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: error!.startsWith('Result:')
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              border: Border.all(
                color: error!.startsWith('Result:')
                    ? Colors.green.shade300
                    : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  error!.startsWith('Result:')
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: error!.startsWith('Result:')
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: error!.startsWith('Result:')
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: CompositedTransformTarget(
            link: layerLink,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
        ),
      ],
    );
  }
}
