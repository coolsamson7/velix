import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/property_panel/compound_property_editor.dart';
import 'package:velix_editor/property_panel/editor/string_editor.dart';
import 'package:velix_ui/provider/environment_provider.dart';

import '../../commands/command.dart';
import '../../commands/command_stack.dart';
import '../../commands/property_changed_command.dart';
import '../../metadata/metadata.dart';
import '../../metadata/properties/properties.dart' hide Border;
import '../../util/message_bus.dart';
import '../editor_builder.dart';
import 'code_editor.dart';

class ValueField extends StatefulWidget {
  // instance data

  final PropertyDescriptor property;
  final dynamic object;
  final Value? value;
  final ValueChanged<dynamic> onChanged;

  // constructor

  const ValueField({
    super.key,

    required this.property,
    required this.value,
    required this.object,
    required this.onChanged,
  });

  // override

  @override
  State<ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<ValueField> {
  // instance data

  late Environment environment;
  late CommandStack commandStack;

  var  propertyDescriptor = CompoundPropertyEditor.getTypeProperties(TypeDescriptor.forType<Value>())[1];
  
  Command? currentCommand;
  Command? parentCommand;

  Value? value;

  ValueType get mode => value!.type;

  // internal
  
  PropertyDescriptor findValueProperty(String name) {
    return CompoundPropertyEditor.getTypeProperties(TypeDescriptor.forType<Value>()).firstWhere((prop) => prop.name == name);
  }

  bool isPropertyChangeCommand(Command command, String property) {
    if (command is PropertyChangeCommand) {
      if (command.target != value) return false;
      if (command.property != property) return false;

      return true;
    }
    return false;
  }

  void changedProperty(String property, dynamic newValue) {
    // set the value

    var typeDescriptor = TypeDescriptor.forType(widget.object.runtimeType);

    if ( typeDescriptor.get(widget.object, widget.property.name) == null) {
      // value is null, set the constructed compound

      parentCommand = commandStack.execute(PropertyChangeCommand(
        bus: environment.get<MessageBus>(),
        widget: widget.object,
        descriptor: typeDescriptor,
        target: widget.object,
        property: widget.property.name, // the value property name!
        newValue: value, // the created compound
      ));

      // how to remember as the new parent?
    }

    if (currentCommand == null || !isPropertyChangeCommand(currentCommand!, property)) {
      currentCommand = commandStack.execute(PropertyChangeCommand(
        bus: environment.get<MessageBus>(),
        parent: parentCommand,
        widget: widget.object,
        descriptor: TypeDescriptor.forType<Value>(),
        target: value!,
        property: property,
        newValue: newValue,
      ));
    }
    else {
      (currentCommand as PropertyChangeCommand).value = newValue;
    }
    setState(() {});
  }

  void _resetProperty(String property) {
    currentCommand = null;
    commandStack.revert(value, property);
    setState(() {});
  }

  Widget _buildEditor() {
    PropertyEditorBuilder builder;
    switch (mode) {
      case ValueType.i18n:
        builder = environment.get<StringEditorBuilder>();
        break;
      case ValueType.binding:
        builder = environment.get<CodeEditorBuilder>();
        break;
      case ValueType.value:
        builder = environment.get<StringEditorBuilder>();
    }

    return builder.buildEditor(
        environment: environment,
        messageBus: environment.get<MessageBus>(),
        commandStack: commandStack,
        property: findValueProperty("value"),
        object: value,
        label: "label",
        value: value!.value,
        onChanged: (newVal) => changedProperty("value", newVal)
    );
  }

  IconData _modeIcon(ValueType mode) {
    switch (mode) {
      case ValueType.i18n:
        return Icons.language; // 🌐
      case ValueType.binding:
        return Icons.link; // 🔗
      case ValueType.value:
        return Icons.edit; // ✏️
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    commandStack = environment.get<CommandStack>();
  }

  @override
  void initState() {
    super.initState();

    value = widget.value ?? Value(type: ValueType.value, value: "");
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildEditor()),
        const SizedBox(width: 4),
        DropdownButton<ValueType>(
          value: mode,
          underline: const SizedBox(),
          //icon: Icon(_modeIcon(_mode)),
          items: ValueType.values.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Icon(_modeIcon(mode)),
            );
          }).toList(),
          onChanged: (mode) {
            if (mode != null) {
              setState(() => changedProperty("type", mode));
            }
          },
        ),
      ],
    );
  }
}


@Injectable()
class ValueEditorBuilder extends PropertyEditorBuilder<Value> {
  // override

  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return ValueField(
      object: object,
      property: property,
      value: value,
      onChanged: onChanged,
    );
  }
}
