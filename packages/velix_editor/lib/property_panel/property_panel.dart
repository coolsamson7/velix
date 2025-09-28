import 'dart:async';
import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/property_panel/compound_property_editor.dart';

import '../commands/command.dart';
import '../commands/command_stack.dart';
import '../commands/property_changed_command.dart';
import '../components/panel_header.dart';
import '../event/events.dart';
import '../metadata/metadata.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import 'package:velix_ui/provider/environment_provider.dart';
import '../util/message_bus.dart';
import 'editor_builder.dart';
import 'editor_registry.dart';

class PropertyPanel extends StatefulWidget {
  final VoidCallback onClose;

  const PropertyPanel({required this.onClose, super.key});

  @override
  State<PropertyPanel> createState() => _PropertyPanelState();
}

class _PropertyPanelState extends State<PropertyPanel> {
  //instance data

  WidgetData? selected;
  WidgetDescriptor? widgetDescriptor;
  late final Environment environment;
  late final MessageBus bus;
  late final CommandStack commandStack;
  late final PropertyEditorBuilderFactory editorRegistry;
  StreamSubscription? subscription;
  late final TypeRegistry typeRegistry;
  final Map<String, bool> _expandedGroups = {};
  Command? currentCommand;

  // internal

  bool isPropertyChangeCommand(Command command, String property) {
    if (command is PropertyChangeCommand) {
      if (command.target != selected) return false;
      if (command.property != property) return false;
      return true;
    }
    return false;
  }

  void changedProperty(String property, dynamic value) {
    if (currentCommand == null || !isPropertyChangeCommand(currentCommand!, property)) {
      currentCommand = commandStack.execute(PropertyChangeCommand(
        bus: bus,
        widget: selected!,
        descriptor: widgetDescriptor!.type,
        target: selected!,
        property: property,
        newValue: value,
      ));
    } else {
      (currentCommand as PropertyChangeCommand).value = value;
    }
    setState(() {});
  }

  void _resetProperty(PropertyDescriptor property) {
    currentCommand = null;
    commandStack.revert(selected, property.name);
    setState(() {});
  }

  bool isPropertyDirty(PropertyDescriptor property) {
    return commandStack.propertyIsDirty(selected, property.name);
  }

  PropertyEditorBuilder? getBuilder(PropertyDescriptor property) {
    if ( property.editor != null)
      return environment.get(type: property.editor);
    else
      return editorRegistry.getBuilder(property.type);
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    bus = environment.get<MessageBus>();
    typeRegistry = environment.get<TypeRegistry>();
    editorRegistry = environment.get<PropertyEditorBuilderFactory>();
    commandStack = environment.get<CommandStack>();

    commandStack.addListener(() => setState(() {}));

    subscription ??= bus.subscribe<SelectionEvent>("selection", (event) {
      setState(() => selected = event.selection);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      widgetDescriptor = null;
      return const Center(child: Text("No selection"));
    }

    widgetDescriptor = typeRegistry[selected!.type];

    // Group properties by group
    final groupedProps = <String, List<PropertyDescriptor>>{};
    for (var prop in widgetDescriptor!.properties) {
      if (!prop.hide) {
        groupedProps.putIfAbsent(prop.group, () => []).add(prop);
      }
    }

    final sortedGroupNames = groupedProps.keys.toList()..sort();


    return PanelContainer(
      title: selected!.type,
      icon:  widgetDescriptor?.icon,
      onClose: widget.onClose,
      child: ListView(
        children: sortedGroupNames.map((groupName) {
          final props = groupedProps[groupName]!..sort((a, b) => a.name.compareTo(b.name));
          _expandedGroups.putIfAbsent(groupName, () => true);
          final isExpanded = _expandedGroups[groupName]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _expandedGroups[groupName] = !isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      // Animated arrow rotation
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0, // 0 = >, 0.25 = v
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right, size: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(groupName, style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900, // header text
                        ),),
                    ],
                  ),
                ),
              ),
              // Animated expansion of the group content
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: props.map((prop) {
                      final editorBuilder = getBuilder(prop);
                      final isCompound = editorBuilder == null && TypeDescriptor.hasType(prop.type);
                      final value = widgetDescriptor!.get(selected!, prop.name);
                      final property = widgetDescriptor!.type.getField(prop.name);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: isCompound
                            ? CompoundPropertyEditor(
                          property: prop,
                          label: prop.label,
                          value: value,
                          target: selected!,
                          descriptor: widgetDescriptor!,
                          editorRegistry: editorRegistry,
                          bus: bus,
                          commandStack: commandStack,
                        )
                            : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  Text(prop.label,
                                      style: const TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  if (isPropertyDirty(prop))
                                    GestureDetector(
                                      onTap: () => _resetProperty(prop),
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
                                messageBus: bus,
                                commandStack: commandStack,
                                label: prop.name,
                                object: selected,
                                property: property,
                                value: value,
                                onChanged: (newVal) =>
                                    changedProperty(prop.name, newVal),
                              )
                                  : Text("No editor for ${prop.name}"),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
