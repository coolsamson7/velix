import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_mapper/mapper/json.dart';

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
import '../validate/validate.dart';
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

class EditContext {
  // instance data

  ClassDesc type;

  // constructor

  EditContext({required this.type});
}

// the overall screen, that combines all aspects
class EditorScreen extends StatefulWidget {
  // instance data

  final List<WidgetData> models;

  // constructor

  const EditorScreen({super.key, required this.models});

  // override

  @override
  State<EditorScreen> createState() => EditorScreenState();
}

@Dataclass()
class EditorScreenState extends State<EditorScreen> with CommandController<EditorScreen>, EditorScreenStateCommands, TickerProviderStateMixin  {
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
  Future<void> _open() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final contents = await file.readAsString();

      var widget = JSON.deserialize<WidgetData>(jsonDecode(contents));

      setState(() {
       print(widget); // TODO
      });
    }
  }

  @Command(i18n: "editor:commands.save", icon: Icons.save)
  @override
  void _save() {
    var root = widget.models[0]; // TODO

    try {
      environment.get<WidgetValidator>().validate(root, type: registry.getClass("Page"), environment: environment); // TODO
    }
    on ValidationException catch (e) {
      environment.get<MessageBus>().publish("messages", MessageEvent(
          source: this,
          type: MessageEventType.add,
          messages: e.errors.map((error) =>  Message(
              type: MessageType.error,
              message: "${error.exception.toString()}", // TODO
             onClick: null
          )).toList()
      ));
    }
  }

  @Command(i18n: "editor:commands.revert", icon: Icons.restore)
  @override
  void _revert() {
    commandStack.undo(); // TODO

    updateCommandState();
  }

  @Command(i18n: "editor:commands.undo", icon: Icons.undo)
  @override
  void _undo() {
    commandStack.undo();

    updateCommandState();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
        bus.publish("load", LoadEvent(widget: widget.models.first, source: this));
        bus.publish("messages", MessageEvent(source: this, type: MessageEventType.add, messages: [
          Message(type: MessageType.warning, message: "oh dear"),
          Message(type: MessageType.error, message: "damnit")
        ]));
    });

    updateCommandState();
    
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentProvider(
      environment: environment,
      child: Provider<EditContext>.value(
          value: EditContext(type: registry.getClass("Page")), // TODO
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
                      child: DockingContainer(
                        left: Dock(
                          panels: [
                            Panel(
                              name: 'tree',
                              label: 'editor:docks.tree.label'.tr(),
                              tooltip: 'editor:docks.tree.tooltip'.tr(),
                              create: (onClose) => FocusableRegion(child: WidgetTreePanel(models: widget.models, onClose: onClose)),
                              icon: Icons.account_tree
                            ),
                            Panel(
                                name: 'palette',
                                label: 'editor:docks.palette.label'.tr(),
                                tooltip: 'editor:docks.palette.tooltip'.tr(),
                                create: (onClose) => WidgetPalette(typeRegistry: environment.get<TypeRegistry>(), onClose: onClose),
                                icon: Icons.widgets
                            ),
                            Panel(
                                name: 'editor',
                                label: 'editor:docks.json.label'.tr(),
                                tooltip: 'editor:docks.json.tooltip'.tr(),
                                create: (onClose) => JsonEditorPanel(model: widget.models.first, onClose: onClose),
                                icon: Icons.code
                            )
                          ],
                          initialPanel: "tree",
                          size: 240,
                        ),
                        right: Dock(
                          panels: [
                            Panel(
                                name: 'properties',
                                label: 'editor:docks.properties.label'.tr(),
                                tooltip: 'editor:docks.properties.tooltip'.tr(),
                                icon: Icons.tune,
                                create: (onClose) => PropertyPanel(onClose: onClose),
                            )
                          ],
                          initialPanel: "properties",
                          size: 280,
                        ),
                        bottom: Dock(
                          panels: [
                            Panel(
                                name: 'errors',
                                label: 'editor:docks.errors.label'.tr(),
                                tooltip: 'editor:docks.errors.tooltip'.tr(),
                                icon: Icons.bug_report,
                                create:  (onClose) => MessagePane(onClose: onClose)
                            )
                          ],
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
                                  messageBus: environment.get<MessageBus>(),
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