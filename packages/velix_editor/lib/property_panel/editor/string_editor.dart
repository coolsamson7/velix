import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class StringEditorBuilder extends PropertyEditorBuilder<String> {
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
    return _StringEditorStateful(
      label: label,
      value: value ?? "",
      onChanged: onChanged,
    );
  }
}

class _StringEditorStateful extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<dynamic> onChanged;

  const _StringEditorStateful({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_StringEditorStateful> createState() => _StringEditorStatefulState();
}

class _StringEditorStatefulState extends State<_StringEditorStateful> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _StringEditorStateful oldWidget) {
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