import 'package:flutter/material.dart';

import 'package:velix_di/di/di.dart';
import 'package:velix_ui/commands/command.dart';


import '../commands/command_stack.dart';
import '../event/events.dart';
import '../json/json_view.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import '../palette/palette_view.dart';
import '../property_panel/property_panel.dart';
import 'package:velix_ui/provider/environment_provider.dart';
import '../tree/tree_view.dart';
import '../util/message_bus.dart';
import '../widget_container.dart';
import 'canvas.dart';
import 'panel_switcher.dart';
import 'widget_breadcrumb.dart';

part "editor.command.g.dart";

// the overall screen, that combines all aspects
class EditorScreen extends StatefulWidget {
  // instance data

  final List<WidgetData> models;

  // constructor

  const EditorScreen({super.key, required this.models});

  // override

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with CommandController<EditorScreen>, _EditorScreenStateCommands, TickerProviderStateMixin  {
  // instance data

  late final Environment environment;
  late final CommandStack commandStack;
  bool edit = true;

  // internal

  bool isDirty() {
    return commandStack.isDirty();
  }

  IconButton button(String commandName) {
    var command = getCommand(commandName);

    return IconButton(
      tooltip: command.label ?? command.name,
      icon: Icon(command.icon),
      onPressed: command.enabled ? () {
        command.execute([]);
      } : null,
    );
  }

  // commands

  @Command(i18n: "commands.open", icon: Icons.folder_open)
  @override
  void _open() {}

  @Command(label: "Save", icon: Icons.save)
  @override
  void _save() {}

  @Command(label: "Revert", icon: Icons.restore)
  @override
  void _revert() {
    commandStack.undo();
  }

  @Command(label: "Undo", icon: Icons.undo)
  @override
  void _undo() {
    commandStack.undo();
  }

  @Command(label: "Play", icon: Icons.play_arrow)
  @override
  void _play() {
    edit = !edit;
    setState(() {});
  }

  // override

  @override
  void updateCommandState() {
    setCommandEnabled("play", true);
    setCommandEnabled("undo", commandStack.isDirty());
    setCommandEnabled("revert", commandStack.isDirty());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = Environment(parent: EnvironmentProvider.of(context));

    // create

    var bus = environment.get<MessageBus>();
    commandStack = environment.get<CommandStack>();

    commandStack.addListener(() => setState(() {
      updateCommandState();
    }));

    WidgetsBinding.instance.addPostFrameCallback((_) =>
        bus.publish("load", LoadEvent(widget: widget.models.first, source: this)));

    updateCommandState();
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentProvider(
      environment: environment,
      child: Column(
        children: [
          // ===== Toolbar =====
          Container(
            height: 48,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                button("open"),
                button("save"),
                button("revert"),
                button("undo"),

                IconButton(
                  tooltip: edit ? "Play" : "Stop",
                  icon: edit ? const Icon(Icons.play_arrow) : const Icon(Icons.stop),
                  onPressed: () {
                    play();
                  },
                ),
                const Spacer(),
                // Optional: add extra buttons or status indicators
                Text("Status: Ready", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),

          // ===== Main Editor =====
          Expanded(
            child: Row(
              children: [
                DockedPanelSwitcher(
                  side: DockSide.left,
                  panels: {
                    "tree": (onClose) => WidgetTreePanel(models: widget.models, onClose: onClose),
                    "palette": (onClose) => WidgetPalette(typeRegistry: environment.get<TypeRegistry>(), onClose: onClose),
                    "json": (onClose) => JsonEditorPanel(model: widget.models.first, onClose: onClose),
                  },
                  icons: {
                    "tree": Icons.account_tree,
                    "palette": Icons.widgets,
                    "json": Icons.code,
                  },
                  initialPanel: "tree",
                ),

                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: edit ?
                          EditorCanvas(
                            models: widget.models,
                            typeRegistry: environment.get<TypeRegistry>(),
                          ) :
                          WidgetContainer(
                            models: widget.models,
                            typeRegistry: environment.get<TypeRegistry>()
                          ),
                      ),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade400, width: 0.5),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: WidgetBreadcrumbWidget(),
                        ),
                      ),
                    ],
                  ),
                ),
                //Container(width: 300, color: Colors.white, child: PropertyPanel()),
                DockedPanelSwitcher(
                  side: DockSide.right,
                  panels: {
                    "properties": (onClose) => PropertyPanel(onClose: onClose),
                  },
                  icons: {
                    "properties": Icons.tune,
                  },
                  initialPanel: "properties",
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}