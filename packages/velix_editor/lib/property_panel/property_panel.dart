import 'dart:async';

import 'package:flutter/material.dart' hide MetaData;

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
import 'editor_registry.dart';


class PropertyPanel extends StatefulWidget {
  const PropertyPanel({super.key});

  @override
  State<PropertyPanel> createState() => _PropertyPanelState();
}

class _PropertyPanelState extends State<PropertyPanel> {
  // instance data

  WidgetData? selected;
  MetaData? metaData;
  late final MessageBus bus;
  late final CommandStack commandStack;
  late final PropertyEditorRegistry editorRegistry;
  StreamSubscription? subscription;
  late final TypeRegistry typeRegistry;
  final Map<String, bool> _expandedGroups = {};
  Command? currentCommand;

  // internal

  bool isPropertyChangeCommand(Command command, String property) {
    if ( command is PropertyChangeCommand) {
      if (command.target != selected)
        return false;

      if (command.property != property)
        return false;
      
      return true;
    }

    return false;
  }

  void changedProperty(String property, dynamic value) {
    // take care of command stack

    if (currentCommand == null || !isPropertyChangeCommand(currentCommand!, property)) 
      currentCommand = commandStack.addCommand(PropertyChangeCommand(
        bus: bus,
        metaData: metaData!,
        target: selected!,
        property: property,
        newValue: value
      ));
    else (currentCommand as PropertyChangeCommand).value = value;
  }

  void _resetProperty(Property property) {
    currentCommand = null;
    commandStack.revert(selected, property.name);

    setState(() {currentCommand = null;});
  }

  bool isPropertyDirty(Property property) {
    var dirty = commandStack.propertyIsDirty(selected, property.name);

    return dirty;
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var environment = EnvironmentProvider.of(context);

    bus = environment.get<MessageBus>();
    typeRegistry = environment.get<TypeRegistry>();
    editorRegistry = environment.get<PropertyEditorRegistry>();
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
      metaData = null;
      return const Center(child: Text("No selection"));
    }

    metaData = typeRegistry[selected!.type];

    // Group properties by group
    final groupedProps = <String, List<Property>>{};
    for (var prop in metaData!.properties)
      if ( !prop.hide) {
        groupedProps.putIfAbsent(prop.group, () => []).add(prop);
      }

    final sortedGroupNames = groupedProps.keys.toList()..sort();

    return PanelContainer(
      title: selected != null ? selected!.type : "Properties",
      child: ListView(
        children: sortedGroupNames.map((groupName) {
          final props = groupedProps[groupName]!..sort((a, b) => a.name.compareTo(b.name));
          _expandedGroups.putIfAbsent(groupName, () => true);

          return ExpansionPanelList(
            expansionCallback: (index, isExpanded) {
              setState(() {
                _expandedGroups[groupName] = !isExpanded;
              });
            },
            elevation: 0,
            expandedHeaderPadding: EdgeInsets.zero,
            children: [
              ExpansionPanel(
                canTapOnHeader: true,
                headerBuilder: (context, isExpanded) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    groupName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                body: Column(
                  children: props.map((prop) {
                    final editorBuilder = editorRegistry.resolve(prop.type);
                    final value = metaData!.get(selected!, prop.name);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property name + dirty indicator
                          SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                Text(
                                  prop.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 4),
                                if (isPropertyDirty(prop))
                                  GestureDetector(
                                    onTap: () => _resetProperty(prop), // call your reset logic
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
                          // Editor widget
                          Expanded(
                            child: editorBuilder != null ?
                              editorBuilder.buildEditor(
                                label: prop.name,
                                value: value,
                                onChanged: (newVal) => changedProperty(prop.name, newVal),
                              ) :
                            Text("No editor for ${prop.name}"),
                          ),
                        ],
                      )
                    );
                  }).toList(),
                ),
                isExpanded: _expandedGroups[groupName]!,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}