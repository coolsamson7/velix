import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:expressions/expressions.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

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
          child: DotAccessExpressionEditor(),
        ),
      ),
    );
  }
}

final Map<String, dynamic> classMetadata = {
  "User": {
    "fields": {"name": "String", "age": "int"},
    "methods": {"greet": {"params": [], "returnType": "String"}}
  },
  "Car": {
    "fields": {"brand": "String", "speed": "double"},
    "methods": {"accelerate": {"params": ["double"], "returnType": "void"}}
  }
};

// Sample data for evaluation
final Map<String, dynamic> sampleData = {
  "User": {
    "name": "John Doe",
    "age": 25,
    "greet": () => "Hello from John!"
  },
  "Car": {
    "brand": "Toyota",
    "speed": 80.5,
    "accelerate": (double amount) => "Accelerating by $amount"
  }
};

class DotAccessExpressionEditor extends StatefulWidget {
  const DotAccessExpressionEditor({super.key});

  @override
  State<DotAccessExpressionEditor> createState() =>
      _DotAccessExpressionEditorState();
}

class _DotAccessExpressionEditorState extends State<DotAccessExpressionEditor> {
  final controller = CodeController(text: '', language: dart);
  final GlobalKey _codeFieldKey = GlobalKey();
  String? error;
  List<String> suggestions = [];
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // No controller listener - we'll use onChanged instead
  }

  @override
  void dispose() {
    controller.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  String get _caretWord {
    final text = controller.text;
    final offset = controller.selection.base.offset;
    if (offset <= 0) return '';

    int start = offset - 1;
    while (start > 0 && !" .\n()[]{}+\-*/=<>!&|,".contains(text[start - 1])) {
      start--;
    }
    return text.substring(start, offset);
  }

  void _onTextChanged(String text) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce to avoid too many suggestion updates
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _showSuggestionsIfNeeded();
    });

    _validateExpression(text);
  }

  void _showSuggestionsIfNeeded() {
    final word = _caretWord;
    if (word.isEmpty) {
      _removeOverlay();
      return;
    }
    final s = _getSuggestions(word);
    if (s.isNotEmpty) {
      suggestions = s;
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _removeOverlay();

    // Get the RenderBox of the CodeField widget
    final RenderBox? renderBox = _codeFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Calculate cursor position (approximation)
    final lines = controller.text.substring(0, controller.selection.base.offset).split('\n');
    final currentLine = lines.length - 1;
    final lineHeight = 20.0; // Approximate line height
    final cursorY = currentLine * lineHeight;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx + 20, // Small offset from left edge
          top: offset.dy + cursorY + 30, // Position near cursor
          width: 280,
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
                  final isMethod = parts.length == 2 &&
                      classMetadata[parts[0]]?['methods']?.containsKey(parts[1]) == true;

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isMethod ? Icons.functions :
                      (parts.length == 2 ? Icons.data_object : Icons.class_),
                      size: 16,
                      color: isMethod ? Colors.purple :
                      (parts.length == 2 ? Colors.blue : Colors.green),
                    ),
                    title: Text(
                      suggestion,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    subtitle: _getSubtitle(suggestion),
                    onTap: () => _insertSuggestion(suggestion),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  Widget? _getSubtitle(String suggestion) {
    final parts = suggestion.split('.');
    if (parts.length == 2) {
      final className = parts[0];
      final memberName = parts[1];
      final classData = classMetadata[className];
      if (classData != null) {
        if (classData['methods']?.containsKey(memberName) == true) {
          final methodData = classData['methods'][memberName];
          final params = methodData['params'] as List;
          final returnType = methodData['returnType'];
          return Text(
            'Method: (${params.join(', ')}) → $returnType',
            style: const TextStyle(fontSize: 11),
          );
        } else if (classData['fields']?.containsKey(memberName) == true) {
          final fieldType = classData['fields'][memberName];
          return Text(
            'Field: $fieldType',
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
    final selection = controller.selection;
    final caret = selection.base.offset;
    int start = caret - 1;
    while (start > 0 && !" .\n()[]{}+\-*/=<>!&|,".contains(text[start - 1])) {
      start--;
    }
    final before = text.substring(0, start);
    final after = text.substring(caret);
    setState(() {
      controller.text = before + suggestion + after;
      controller.selection = TextSelection.collapsed(offset: before.length + suggestion.length);
    });
    _removeOverlay();
    _validateExpression(controller.text);
  }

  void _validateExpression(String input) {
    if (input.trim().isEmpty) {
      setState(() => error = null);
      return;
    }

    try {
      final expression = Expression.parse(input);
      final evaluator = const ExpressionEvaluator();

      // Create evaluation context with sample data
      final context = <String, dynamic>{};

      // Add flattened access to sample data
      for (final entry in sampleData.entries) {
        final className = entry.key;
        final classInstance = entry.value as Map<String, dynamic>;

        // Add direct class reference
        context[className] = classInstance;

        // Add dot-notation access
        for (final member in classInstance.entries) {
          context['$className.${member.key}'] = member.value;
        }
      }

      // Try to evaluate the expression
      final result = evaluator.eval(expression, context);
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
        if (!classMetadata.containsKey(className)) return [];
        final classData = classMetadata[className]!;
        final suggestions = <String>[];

        // Add field suggestions
        for (var f in (classData['fields'] as Map).keys) {
          if (f.startsWith(partial)) {
            suggestions.add('$className.$f');
          }
        }

        // Add method suggestions
        for (var m in (classData['methods'] as Map).keys) {
          if (m.startsWith(partial)) {
            suggestions.add('$className.$m');
          }
        }
        return suggestions;
      }
    } else {
      return classMetadata.keys.where((c) => c.startsWith(pattern)).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Error/Result display
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

        // Code editor
        Expanded(
          child: Container(
            key: _codeFieldKey,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onTap: _removeOverlay,
              child: CodeTheme(
                data: CodeThemeData(styles: monokaiSublimeTheme),
                child: CodeField(
                  controller: controller,
                  textStyle: const TextStyle(fontFamily: 'monospace'),
                  onChanged: _onTextChanged,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Help text
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available for testing:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'User.name = "John Doe"\n'
                      'User.age = 25\n'
                      'Car.brand = "Toyota"\n'
                      'Car.speed = 80.5\n\n'
                      'Try: User.name + " is " + User.age + " years old"',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}