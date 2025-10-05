import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command.dart';
import '../../commands/command_stack.dart';
import '../../commands/property_changed_command.dart';
import '../../metadata/metadata.dart';
import '../../metadata/properties/properties.dart' as m show Insets;
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class PaddingEditorBuilder extends PropertyEditorBuilder<m.Insets> {
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
    return PaddingEditor(
      messageBus: messageBus,
      commandStack: commandStack,
      label: label,
      object: object,
      property: property,
      value: value,
      onChanged: onChanged,
    );
  }
}

class PaddingEditor extends StatefulWidget {
  final String label;
  final m.Insets? value;
  final ValueChanged<EdgeInsets> onChanged;

  final PropertyDescriptor property;
  final dynamic object;
  final CommandStack commandStack;
  final MessageBus messageBus;

  const PaddingEditor({
    Key? key,
    required this.messageBus,
    required this.commandStack,
    required this.property,
    required this.object,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PaddingEditor> createState() => _PaddingEditorState();
}

class _PaddingEditorState extends State<PaddingEditor> {
  late final TextEditingController topController;
  late final TextEditingController leftController;
  late final TextEditingController rightController;
  late final TextEditingController bottomController;

  late m.Insets value;

  Command? currentCommand;
  Command? parentCommand;

  @override
  void initState() {
    super.initState();
    value = widget.value ?? m.Insets();

    topController = TextEditingController(text: value.top.toString());
    leftController = TextEditingController(text: value.left.toString());
    rightController = TextEditingController(text: value.right.toString());
    bottomController = TextEditingController(text: value.bottom.toString());
  }

  @override
  void didUpdateWidget(covariant PaddingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      value = widget.value ?? m.Insets();
      parentCommand = null;
      currentCommand = null;

      topController.text = value.top.toString();
      leftController.text = value.left.toString();
      rightController.text = value.right.toString();
      bottomController.text = value.bottom.toString();
    }
  }

  @override
  void dispose() {
    topController.dispose();
    leftController.dispose();
    rightController.dispose();
    bottomController.dispose();
    super.dispose();
  }

  m.Insets createPadding() {
    final top = int.tryParse(topController.text) ?? 0;
    final left = int.tryParse(leftController.text) ?? 0;
    final right = int.tryParse(rightController.text) ?? 0;
    final bottom = int.tryParse(bottomController.text) ?? 0;
    return m.Insets(left: left, top: top, right: right, bottom: bottom);
  }

  void changedProperty() {
    value = createPadding();

    if (widget.property.get(widget.object) == null) {
      parentCommand = widget.commandStack.execute(PropertyChangeCommand(
        bus: widget.messageBus,
        widget: widget.object,
        descriptor: widget.property.getTypeDescriptor(),
        target: widget.object,
        property: widget.property.name,
        newValue: value,
      ));
    }

    if (currentCommand == null) {
      currentCommand = widget.commandStack.execute(PropertyChangeCommand(
        bus: widget.messageBus,
        parent: parentCommand,
        widget: widget.object,
        descriptor: widget.property.getTypeDescriptor(),
        target: widget.object,
        property: widget.property.name,
        newValue: value,
      ));
    } else {
      (currentCommand as PropertyChangeCommand).value = value;
    }

    setState(() {});
    //widget.onChanged(value.toEdgeInsets());
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onChanged: (_) => changedProperty(),
            onSubmitted: (_) => changedProperty(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildField('Top', topController),
        const SizedBox(width: 8),
        _buildField('Left', leftController),
        const SizedBox(width: 8),
        _buildField('Right', rightController),
        const SizedBox(width: 8),
        _buildField('Bottom', bottomController),
      ],
    );
  }
}
