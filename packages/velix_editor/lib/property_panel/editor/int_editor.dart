import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command_stack.dart';
import '../../metadata/metadata.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class IntEditorBuilder extends PropertyEditorBuilder<int> {
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
    return _IntEditorStateful(
      label: label,
      value: value ?? 0,
      onChanged: onChanged,
    );
  }
}

class _IntEditorStateful extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<dynamic> onChanged;

  const _IntEditorStateful({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_IntEditorStateful> createState() => _IntEditorStatefulState();
}

class _IntEditorStatefulState extends State<_IntEditorStateful> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _IntEditorStateful oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value.toString() != _controller.text) {
      // Update controller text if external value has changed
      _controller.text = widget.value.toString();
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
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) {
        final intValue = int.tryParse(val) ?? 0;
        widget.onChanged(intValue);
      },
    );
  }
}
