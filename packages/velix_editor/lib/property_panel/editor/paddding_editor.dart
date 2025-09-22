import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../editor_builder.dart';

@Injectable()
class PaddingEditorBuilder extends PropertyEditorBuilder<Padding> {
  // override

  @override
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return _PaddingEditorStateful(
      label: label,
      value: value ?? "",
      onChanged: onChanged,
    );
  }
}

class _PaddingEditorStateful extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<dynamic> onChanged;

  const _PaddingEditorStateful({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_PaddingEditorStateful> createState() => _PaddingEditorStatefulState();
}

class _PaddingEditorStatefulState extends State<_PaddingEditorStateful> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _PaddingEditorStateful oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
    );
  }
}