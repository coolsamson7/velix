import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';

import 'package:velix_ui/provider/environment_provider.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_i18n/i18n/locale.dart';
import 'package:velix_ui/commands/command.dart';

import '../actions/types.dart';
import '../commands/command_stack.dart';
import '../components/focusable_region.dart';
import '../event/events.dart';
import '../json/json_view.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import '../palette/palette_view.dart';
import '../property_panel/property_panel.dart';

import '../tree/tree_view.dart';
import '../util/message_bus.dart';
import '../widget_container.dart';
import 'canvas.dart';
import 'error_messages.dart';
import 'docking_container.dart';
import 'widget_breadcrumb.dart';

part "editor.command.g.dart";

// TEST TODO

String json = '''
{
  "classes": [
    {
      "name": "Address",
      "superClass": null,
      "properties": [
        {
          "name": "city",
          "type": "String",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        },
        {
          "name": "street",
          "type": "String",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        }
      ],
      "methods": [
        {
          "name": "hello",
          "parameters": [
            {
              "name": "message",
              "type": "String",
              "isNamed": false,
              "isRequired": true,
              "isNullable": false
            }
          ],
          "returnType": "String",
          "isAsync": false,
          "annotations": [
            {
              "name": "Inject",
              "value": "Inject"
            }
          ]
        }
      ],
      "annotations": [
        {
          "name": "Dataclass",
          "value": "Dataclass"
        }
      ],
      "isAbstract": false,
      "location": "13:1"
    },
    {
      "name": "User",
      "superClass": null,
      "properties": [
        {
          "name": "name",
          "type": "String",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        },
         {
          "name": "age",
          "type": "int",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        },
         {
          "name": "cool",
          "type": "bool",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        },
        {
          "name": "address",
          "type": "Address",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        }
      ],
      "methods": [
        {
          "name": "hello",
          "parameters": [
            {
              "name": "message",
              "type": "String",
              "isNamed": false,
              "isRequired": true,
              "isNullable": false
            }
          ],
          "returnType": "String",
          "isAsync": false,
          "annotations": [
            {
              "name": "Inject",
              "value": "Inject"
            }
          ]
        }
      ],
      "annotations": [
        {
          "name": "Dataclass",
          "value": "Dataclass"
        }
      ],
      "isAbstract": false,
      "location": "34:1"
    },
    {
      "name": "Page",
      "superClass": null,
      "properties": [
        {
          "name": "user",
          "type": "User",
          "isNullable": false,
          "isFinal": true,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        }
      ],
      "methods": [
        {
          "name": "setup",
          "parameters": [],
          "returnType": "void",
          "isAsync": false,
          "annotations": [
            {
              "name": "Inject",
              "value": "Inject"
            }
          ]
        }
      ],
      "annotations": [
        {
          "name": "Injectable",
          "value": "Injectable"
        },
        {
          "name": "Dataclass",
          "value": "Dataclass"
        }
      ],
      "isAbstract": false,
      "location": "56:1"
    }
  ]
}
''';

var registry = ClassRegistry()..read(jsonDecode(json)["classes"]);

@Dataclass()
class Address {
  // instance data

  @Attribute()
  String city = "";
  @Attribute()
  String street = "";

  // constructor

  Address({required this.city, required this.street});

  // methods

  @Inject()
  String hello(String message, ) {
    return "world";
  }
}

@Dataclass()
class User {
  // instance data

  @Attribute()
  String name = "";
  @Attribute()
  int age;
  @Attribute()
  Address address;
  @Attribute()
  bool cool;

  // constructor

  User({required this.name, required this.address, required this.age, required this.cool});

  // methods

  @Inject()
  String hello(String message) {
    return "hello $message";
  }
}

@Injectable()
@Dataclass()
class Page {
  // instance data

  @Attribute()
  User user;

  // constructor

  Page() : user = User(
      name: "Andreas",
      age: 60,
      cool: true,
      address: Address(
          city: "Cologne",
          street: "Neumarkt"
      ));

  // methods

  @Inject()
  void setup() {
    print("setup");
  }
}

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

  late final LocaleManager localeManager;

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
        command.execute();
      } : null,
    );
  }

  void switchLocale(String locale) {
    Provider.of<LocaleManager>(context, listen: false).locale = Locale(locale);
  }

  // commands

  @Command(i18n: "editor:commands.open", icon: Icons.folder_open)
  @override
  void _open() {}

  @Command(i18n: "editor:commands.save", icon: Icons.save)
  @override
  void _save() {}

  @Command(i18n: "editor:commands.revert", icon: Icons.restore)
  @override
  void _revert() {
    commandStack.undo();
  }

  @Command(i18n: "editor:commands.undo", icon: Icons.undo)
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
      child: Provider<ClassDesc>.value(
          value: registry.getClass("Page"),
          child: FocusScope(
            autofocus: true,
            child: Shortcuts(
              shortcuts: computeShortcuts(),
              child: Actions(
                actions: {
                  CommandIntent: CommandAction(),
                },
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

                          // === Locale Switcher ===
                          Row(
                            children: [
                              IconButton(
                                tooltip: "English",
                                icon: const Text("🇬🇧", style: TextStyle(fontSize: 20)),
                                onPressed: () {
                                  switchLocale("en");
                                },
                              ),
                              IconButton(
                                tooltip: "Deutsch",
                                icon: const Text("🇩🇪", style: TextStyle(fontSize: 20)),
                                onPressed: () {
                                  switchLocale("de");
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ===== Main Editor =====
                    Expanded(
                      child:
                DockingContainer(
                  left: Dock(
                    panels: {
                      "tree": (onClose) =>
                          FocusableRegion(child: WidgetTreePanel(models: widget.models, onClose: onClose)),
                      "palette": (onClose) =>
                          WidgetPalette(typeRegistry: environment.get<TypeRegistry>(), onClose: onClose),
                      "json": (onClose) => JsonEditorPanel(model: widget.models.first, onClose: onClose),
                    },
                    icons: {
                      "tree": Icons.account_tree,
                      "palette": Icons.widgets,
                      "json": Icons.code,
                    },
                    initialPanel: "tree",
                    size: 240,
                  ),
                  right: Dock(
                    panels: {
                      "properties": (onClose) => PropertyPanel(onClose: onClose),
                    },
                    icons: {
                      "properties": Icons.tune,
                    },
                    initialPanel: "properties",
                    size: 280,
                  ),
                  bottom: Dock(
                    panels: {
                      "errors": (onClose) => BottomErrorDisplay(onClose: onClose, errors: [
                        "Something went wrong",
                        "Another error occurred",
                      ]),
                    },
                    icons: {
                      "errors": Icons.bug_report,
                    },
                    initialPanel: "errors",
                    size: 150,
                    overlay: false, // change to true if you want floating
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child:
                      edit ? FocusableRegion(
                          child: EditorCanvas(
                            models: widget.models,
                            typeRegistry: environment.get<TypeRegistry>(),
                          ),
                        )
                            : WidgetContainer(
                          context: WidgetContext(page: environment.get<Page>()),
                          models: widget.models,
                          typeRegistry: environment.get<TypeRegistry>(),
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
                )

                    )
                ],
                ),
              ),
            )
        )
      )
    );
  }
}