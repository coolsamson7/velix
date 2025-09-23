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

class DotAccessExpressionEditor extends StatefulWidget {
  const DotAccessExpressionEditor({super.key});

  @override
  State<DotAccessExpressionEditor> createState() =>
      _DotAccessExpressionEditorState();
}

class _DotAccessExpressionEditorState extends State<DotAccessExpressionEditor> {
  final controller = CodeController(text: '', language: dart);
  String? error;
  List<String> suggestions = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    controller.addListener(_showSuggestionsIfNeeded);
  }

  @override
  void dispose() {
    controller.removeListener(_showSuggestionsIfNeeded);
    controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  String get _caretWord {
    // Get word before caret, simple version (split by space, dot etc)
    final text = controller.text;
    final offset = controller.selection.base.offset;
    if (offset <= 0) return '';
    int start = offset - 1;
    while (start > 0 && !" .\n()[]{}".contains(text[start - 1])) {
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
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        // The popup can be improved with caret coordinates
        return Positioned(
          left: offset.dx + 32,
          top: offset.dy + 72,
          width: 300,
          child: Material(
            elevation: 4,
            child: ListView(
              shrinkWrap: true,
              children: suggestions.map((s) {
                return ListTile(
                  title: Text(s),
                  onTap: () {
                    _insertSuggestion(s);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
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
    while (start > 0 && !" .\n()[]{}".contains(text[start - 1])) {
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
      evaluator.eval(expression, {});
      setState(() => error = null);
    } catch (e) {
      setState(() => error = 'Syntax error: $e');
    }
  }

  List<String> _getSuggestions(String pattern) {
    // Use same logic as before, but for caret's current partial word only
    if (pattern.contains('.')) {
      final parts = pattern.split('.');
      if (parts.length == 2) {
        final className = parts[0];
        final partial = parts[1];
        if (!classMetadata.containsKey(className)) return [];
        final classData = classMetadata[className]!;
        final suggestions = <String>[];
        for (var f in (classData['fields'] as Map).keys) {
          if (f.startsWith(partial)) suggestions.add('$className.$f');
        }
        for (var m in (classData['methods'] as Map).keys) {
          if (m.startsWith(partial)) suggestions.add('$className.$m');
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
        if (error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
                ),
              ],
            ),
          ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              _removeOverlay();
            },
            child: CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: CodeField(
                controller: controller,
                textStyle: const TextStyle(fontFamily: 'monospace'),
                onChanged: _validateExpression,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
