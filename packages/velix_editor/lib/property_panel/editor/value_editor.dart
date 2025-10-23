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
import '../../metadata/widget_data.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';
import 'code_editor.dart';

class ValueField extends StatefulWidget {
  final PropertyDescriptor property;
  final WidgetData widget;
  final dynamic object;
  final Value? value;
  final ValueChanged<dynamic> onChanged;

  const ValueField({
    super.key,
    required this.widget,
    required this.property,
    required this.value,
    required this.object,
    required this.onChanged,
  });

  @override
  State<ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<ValueField> {
  late Environment environment;
  late CommandStack commandStack;

  var propertyDescriptor = CompoundPropertyEditor.getTypeProperties(TypeDescriptor.forType<Value>())[1];

  Command? currentCommand;
  Command? parentCommand;

  Value? value;

  ValueType get mode => value!.type;

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
    var typeDescriptor = TypeDescriptor.forType(widget.object.runtimeType);

    if (typeDescriptor.get(widget.object, widget.property.name) == null) {
      parentCommand = commandStack.execute(PropertyChangeCommand(
        bus: environment.get<MessageBus>(),
        widget: widget.object,
        descriptor: typeDescriptor,
        target: widget.object,
        property: widget.property.name,
        newValue: value,
      ));
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
    } else {
      (currentCommand as PropertyChangeCommand).value = newValue;
    }
    setState(() {});
  }

  /*void _resetProperty(String property) {
    currentCommand = null;
    commandStack.revert(value, property);
    setState(() {});
  }*/

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
        widget: widget.widget,
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
        return Icons.language;
      case ValueType.binding:
        return Icons.link;
      case ValueType.value:
        return Icons.edit;
    }
  }

  Color _modeColor(ValueType mode) {
    switch (mode) {
      case ValueType.i18n:
        return Colors.blue.shade600;
      case ValueType.binding:
        return Colors.purple.shade600;
      case ValueType.value:
        return Colors.green.shade600;
    }
  }

  String _modeLabel(ValueType mode) {
    switch (mode) {
      case ValueType.i18n:
        return 'Translation';
      case ValueType.binding:
        return 'Binding';
      case ValueType.value:
        return 'Static';
    }
  }

  void _showModeSelectorMenu() {
    final theme = Theme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu<ValueType>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + 200,
        offset.dy + button.size.height,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: ValueType.values.map((mode) {
        final isSelected = mode == this.mode;
        return PopupMenuItem<ValueType>(
          value: mode,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _modeColor(mode).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _modeIcon(mode),
                  color: _modeColor(mode),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _modeLabel(mode),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedMode) {
      if (selectedMode != null && selectedMode != mode) {
        changedProperty("type", selectedMode);
      }
    });
  }

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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7), // Slightly smaller to account for border
        child: Row(
          children: [
            // Mode indicator button on the left
            InkWell(
              onTap: _showModeSelectorMenu,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: _modeColor(mode).withOpacity(0.1),
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _modeIcon(mode),
                      color: _modeColor(mode),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: _modeColor(mode),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            // Editor field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildEditor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Injectable()
class ValueEditorBuilder extends PropertyEditorBuilder<Value> {
  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required WidgetData widget,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return ValueField(
      widget: widget,
      object: object,
      property: property,
      value: value,
      onChanged: onChanged,
    );
  }
}