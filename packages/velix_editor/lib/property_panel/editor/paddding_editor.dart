import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix_di/di/di.dart';

import '../../commands/command.dart';
import '../../commands/property_changed_command.dart';
import '../../metadata/properties/properties.dart' as m show Padding;

import '../editor_builder.dart';

@Injectable()
class PaddingEditorBuilder extends PropertyEditorBuilder<EdgeInsets> {
  @override
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return PaddingEditor(
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }
}

class PaddingEditor extends StatefulWidget {
  // instance data

  final String label;
  final m.Padding value;
  final ValueChanged<EdgeInsets> onChanged;

  // constructor

  const PaddingEditor({
    Key? key,
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

  late final Environment environment;

  dynamic value;

  // internal

  bool isPropertyChangeCommand(Command command, String property) {
    if (command is PropertyChangeCommand) {
      if (command.target != widget.value) return false;
      if (command.property != property) return false;

      return true;
    }
    return false;
  }

  void changedProperty(String property, dynamic value) {
    /*set the value

    if ( widget.descriptor.get(widget.target, widget.property.name) == null) {
      // value is null, set the constructed compound

      parentCommand = widget.commandStack.execute(PropertyChangeCommand(
        bus: widget.bus,
        widget: widget.target,
        descriptor: widget.descriptor.type,
        target: widget.target,
        property: widget.property.name, // the compound name!
        newValue: this.value, // the created compound
      ));

      // how to remember as the new parent?
    }

    if (currentCommand == null || !isPropertyChangeCommand(currentCommand!, property)) {
      currentCommand = widget.commandStack.execute(PropertyChangeCommand(
        bus: widget.bus,
        parent: parentCommand,
        widget: widget.target,
        descriptor: getCompoundDescriptor(),
        target: this.value,
        property: property,
        newValue: value,
      ));
    }
    else {
      (currentCommand as PropertyChangeCommand).value = value;
    }*/
    setState(() {});
  }

  void _resetProperty(String property) {
    currentCommand = null;
    //widget.commandStack.revert(value, property);
    setState(() {});
  }

  // override


  @override
  void initState() {
    super.initState();

    value = widget.value ?? m.Padding();

    topController = TextEditingController(text: widget.value.top.toString());
    leftController = TextEditingController(text: widget.value.left.toString());
    rightController = TextEditingController(text: widget.value.right.toString());
    bottomController = TextEditingController(text: widget.value.bottom.toString());

    topFocus = FocusNode();
    leftFocus = FocusNode();
    rightFocus = FocusNode();
    bottomFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant PaddingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      topController.text = widget.value.top.toString();
      leftController.text = widget.value.left.toString();
      rightController.text = widget.value.right.toString();
      bottomController.text = widget.value.bottom.toString();
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

  void _updatePadding() {
    final top = int.tryParse(topController.text) ?? 0;
    final left = int.tryParse(leftController.text) ?? 0;
    final right = int.tryParse(rightController.text) ?? 0;
    final bottom = int.tryParse(bottomController.text) ?? 0;

    final newPadding = m.Padding(left: left, top: top, right: right, bottom: bottom);

    //widget.onChanged(newPadding);
  }

  Widget _buildPaddingField({
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
              onChanged: (_) => _updatePadding(),
              onSubmitted: (_) => _updatePadding(),
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
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),

        // Padding fields in a row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaddingField(
              prefix: 'T',
              controller: topController,
              focusNode: topFocus,
            ),
            const SizedBox(width: 8),
            _buildPaddingField(
              prefix: 'L',
              controller: leftController,
              focusNode: leftFocus,
            ),
            const SizedBox(width: 8),
            _buildPaddingField(
              prefix: 'R',
              controller: rightController,
              focusNode: rightFocus,
            ),
            const SizedBox(width: 8),
            _buildPaddingField(
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