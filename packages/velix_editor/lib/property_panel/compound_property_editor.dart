import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import '../commands/command.dart';
import '../commands/command_stack.dart';
import '../commands/property_changed_command.dart';
import '../metadata/metadata.dart';
import '../metadata/widget_data.dart';
import '../util/message_bus.dart';
import 'editor_registry.dart';

/// A generic editor for compound/class properties (like TextStyle)
class CompoundPropertyEditor extends StatefulWidget {
  // instance data

  final Property property;
  final String label;
  final dynamic value;
  final WidgetData target;
  final WidgetDescriptor descriptor;
  final PropertyEditorBuilderFactory editorRegistry;
  final MessageBus bus;
  final CommandStack commandStack;

  // constructor

  const CompoundPropertyEditor({
    super.key,
    required this.property,
    required this.label,
    required this.value,
    required this.target,
    required this.descriptor,
    required this.editorRegistry,
    required this.bus,
    required this.commandStack,
  });

  // override

  @override
  State<CompoundPropertyEditor> createState() => _CompoundPropertyEditorState();
}

class _CompoundPropertyEditorState extends State<CompoundPropertyEditor> {
  // instance data

  Command? currentCommand;

  // internal

  TypeDescriptor getCompoundDescriptor() {
    return (widget.property.field.type as ObjectType).typeDescriptor;
  }

  bool isPropertyChangeCommand(Command command, String property) {
    if (command is PropertyChangeCommand) {
      if (command.target != widget.target) return false;
      if (command.property != property) return false;
      return true;
    }
    return false;
  }

  void changedProperty(String property, dynamic value) {
    if (currentCommand == null || !isPropertyChangeCommand(currentCommand!, property)) {
      currentCommand = widget.commandStack.execute(PropertyChangeCommand(
        bus: widget.bus,
        widget: widget.target,
        descriptor: getCompoundDescriptor(),
        target: widget.value,
        property: property,
        newValue: value,
      ));
    } else {
      (currentCommand as PropertyChangeCommand).value = value;
    }
    setState(() {});
  }

  void _resetProperty(String property) {
    currentCommand = null;
    widget.commandStack.revert(widget.value, property);
    setState(() {});
  }

  // override

  @override
  Widget build(BuildContext context) {
    if (widget.value == null) return const SizedBox.shrink();

    var compoundDescriptor = getCompoundDescriptor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: compoundDescriptor.getFields().map((field) {
        final editorBuilder = widget.editorRegistry.getBuilder(field.type.type);
        final value = compoundDescriptor.get(widget.value, field.name);
        final isDirty = widget.commandStack.propertyIsDirty(widget.value, field.name);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Text(field.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    if (isDirty)
                      GestureDetector(
                        onTap: () => _resetProperty(field.name),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: editorBuilder != null
                    ? editorBuilder.buildEditor(
                  label: field.name,
                  value: value,
                  onChanged: (newVal) => changedProperty(field.name, newVal),
                )
                    : Text("No editor for ${field.name}"),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
