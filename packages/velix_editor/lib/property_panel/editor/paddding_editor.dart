import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command.dart';
import '../../commands/command_stack.dart';
import '../../commands/property_changed_command.dart';
import '../../metadata/properties/properties.dart' as m show Padding;

import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class PaddingEditorBuilder extends PropertyEditorBuilder<m.Padding> {
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
  // instance data

  final String label;
  final m.Padding? value;
  final ValueChanged<EdgeInsets> onChanged;

  final FieldDescriptor property;
  final dynamic object;
  final CommandStack commandStack;
  final MessageBus messageBus;

  // constructor

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

  // override

  @override
  State<PaddingEditor> createState() => _PaddingEditorState();
}

class _PaddingEditorState extends State<PaddingEditor> {
  // instance data

  late final TextEditingController topController;
  late final TextEditingController leftController;
  late final TextEditingController rightController;
  late final TextEditingController bottomController;

  late final FocusNode topFocus;
  late final FocusNode leftFocus;
  late final FocusNode rightFocus;
  late final FocusNode bottomFocus;

  Command? currentCommand;
  Command? parentCommand;

  late m.Padding value;

  // internal

  bool isPropertyChangeCommand(Command command, String property) {
    if (command is PropertyChangeCommand) {
      if (command.target != widget.value) return false;
      if (command.property != property) return false;

      return true;
    }
    return false;
  }

  void changedProperty(String property) {
    value = createPadding();

    // set the value

    if ( widget.property.get(widget.object) == null) {
      // value is null, set the constructed compound

      parentCommand = widget.commandStack.execute(PropertyChangeCommand(
        bus: widget.messageBus,
        widget: widget.object,
        descriptor: widget.property.typeDescriptor,
        target: widget.object,
        property: widget.property.name,
        newValue: value,
      ));

      // how to remember as the new parent?
    }

    if (currentCommand == null || !isPropertyChangeCommand(currentCommand!, property)) {
      currentCommand = widget.commandStack.execute(PropertyChangeCommand(
        bus: widget.messageBus,
        parent: parentCommand,
        widget: widget.object,
        descriptor: widget.property.typeDescriptor,
        target: widget.object,
        property: widget.property.name,
        newValue: value,
      ));
    }
    else {
      (currentCommand as PropertyChangeCommand).value = value;
    }
    setState(() {});
  }

  // override

  @override
  void initState() {
    super.initState();

    value = widget.value ?? m.Padding();

    topController = TextEditingController(text: value.top.toString());
    leftController = TextEditingController(text: value.left.toString());
    rightController = TextEditingController(text: value.right.toString());
    bottomController = TextEditingController(text: value.bottom.toString());

    topFocus = FocusNode();
    leftFocus = FocusNode();
    rightFocus = FocusNode();
    bottomFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant PaddingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      value = widget.value ?? m.Padding();

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

    topFocus.dispose();
    leftFocus.dispose();
    rightFocus.dispose();
    bottomFocus.dispose();

    super.dispose();
  }

  m.Padding createPadding() {
    final top = int.tryParse(topController.text) ?? 0;
    final left = int.tryParse(leftController.text) ?? 0;
    final right = int.tryParse(rightController.text) ?? 0;
    final bottom = int.tryParse(bottomController.text) ?? 0;

    return m.Padding(left: left, top: top, right: right, bottom: bottom);
  }

  Widget _buildPaddingField({
    required String name,
    required String prefix,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return SizedBox(
      width: 50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefix,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => changedProperty(name),
              onSubmitted: (_) => changedProperty(name),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Padding fields in a row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaddingField(
              name: "top",
              prefix: 'T',
              controller: topController,
              focusNode: topFocus,
            ),
            const SizedBox(width: 8),
            _buildPaddingField(
              name: "left",
              prefix: 'L',
              controller: leftController,
              focusNode: leftFocus,
            ),
            const SizedBox(width: 8),
            _buildPaddingField(
              name: "right",
              prefix: 'R',
              controller: rightController,
              focusNode: rightFocus,
            ),
            const SizedBox(width: 8),
            _buildPaddingField(
              name: "bottom",
              prefix: 'B',
              controller: bottomController,
              focusNode: bottomFocus,
            ),
          ],
        ),
      ],
    );
  }
}