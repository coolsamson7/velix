import 'dart:async';

import 'package:flutter/material.dart';

import '../components/panel_header.dart';
import '../event/events.dart';
import '../metadata/metadata.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import '../provider/environment_provider.dart';
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
  late final MessageBus bus;
  late final PropertyEditorRegistry editorRegistry;
  StreamSubscription? subscription;
  late final TypeRegistry typeRegistry;
  final Map<String, bool> _expandedGroups = {};

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();
    typeRegistry = EnvironmentProvider.of(context).get<TypeRegistry>();
    editorRegistry = EnvironmentProvider.of(context).get<PropertyEditorRegistry>();

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
      return const Center(child: Text("No selection"));
    }

    final meta = typeRegistry[selected!.type];

    // Group properties by group
    final groupedProps = <String, List<Property>>{};
    for (var prop in meta.properties) {
      groupedProps.putIfAbsent(prop.group, () => []).add(prop);
    }

    final sortedGroupNames = groupedProps.keys.toList()..sort();

    return PanelContainer(
      title: "Properties",
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
                    final editor = editorRegistry.resolve(prop.type);
                    final value = meta.get(selected!, prop.name);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property name
                          SizedBox(
                            width: 100,
                            child: Text(
                              prop.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Editor widget
                          Expanded(
                            child: editor != null
                                ? editor.buildEditor(
                              label: prop.name,
                              value: value,
                              onChanged: (newVal) {
                                meta.set(selected!, prop.name, newVal);
                                bus.publish(
                                  "property-changed",
                                  PropertyChangeEvent(widget: selected, source: this),
                                );
                              },
                            )
                                : Text("No editor for ${prop.name}"),
                          ),
                        ],
                      ),
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