import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:velix/i18n/translator.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/annotations.dart';
import 'package:velix_ui/provider/environment_provider.dart';
import '../commands/command.dart';
import '../commands/command_stack.dart';
import '../commands/property_changed_command.dart';
import '../metadata/metadata.dart';
import '../metadata/widget_data.dart';
import '../util/message_bus.dart';
import 'editor_builder.dart';
import 'editor_registry.dart';

/// A generic editor for compound/class properties (like TextStyle)
class CompoundPropertyEditor extends StatefulWidget {
  // instance data

  final PropertyDescriptor property;
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
  Command? parentCommand;

  late final Environment environment;

  dynamic value;

  // internal

  static Map<TypeDescriptor,Map<String,String>> labels = {};

  Map<String,String> getLabels(TypeDescriptor descriptor) {
    var result = null;// TODO  labels[descriptor];
    if ( result == null) {
      result = HashMap<String,String>();

      for ( var field in descriptor.getFields()) {
        var annotation = field.findAnnotation<DeclareProperty>();

        if ( annotation != null && annotation.label != null)
          result[field.name] = Translator.tr("${annotation.label}.label");
        else
          result[field.name] = field.name;
      }
    }


    return result!;
  }

  TypeDescriptor getCompoundDescriptor() {
    return (widget.property.field.type as ObjectType).typeDescriptor;
  }

  bool isPropertyChangeCommand(Command command, String property) {
    if (command is PropertyChangeCommand) {
      if (command.target != widget.value) return false;
      if (command.property != property) return false;

      return true;
    }
    return false;
  }

  void changedProperty(String property, dynamic value) {
    // set the value

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
    }
    setState(() {});
  }

  void _resetProperty(String property) {
    currentCommand = null;
    widget.commandStack.revert(value, property);
    setState(() {});
  }

  PropertyEditorBuilder getBuilder(PropertyDescriptor property) {
    if ( property.editor != null)
      return environment.get(type: property.editor);
    else
      return widget.editorRegistry.getBuilder(property.type)!;
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
  }

  @override
  void initState() {
    super.initState();

    value = widget.value ?? getCompoundDescriptor().constructor!();
  }

  @override
  Widget build(BuildContext context) {
    var compoundDescriptor = getCompoundDescriptor();

    var labels = getLabels(compoundDescriptor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: compoundDescriptor.getFields().map((field) {
        var editorType = field.findAnnotation<DeclareProperty>()!.editor;

        final editorBuilder = editorType != null  ? environment.get(type: editorType) : widget.editorRegistry.getBuilder(field.type.type);
        final value = compoundDescriptor.get(this.value, field.name);
        final isDirty = widget.commandStack.propertyIsDirty(this.value, field.name);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Text(labels[field.name]!, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                child: editorBuilder != null ? editorBuilder.buildEditor(
                  messageBus: widget.bus,
                  commandStack: widget.commandStack,
                  object: this.value,
                  property: field,
                  label: labels[field.name]!,
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
