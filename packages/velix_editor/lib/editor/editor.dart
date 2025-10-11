import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/editor/settings.dart';
import 'package:velix_editor/editor/settings_panel.dart';
import 'package:velix_editor/metadata/widgets/container.dart';
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_mapper/mapper/json.dart';

import 'package:velix_ui/provider/environment_provider.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_i18n/i18n/locale.dart';
import 'package:velix_ui/commands/command.dart';

import 'package:oktoast/oktoast.dart' as ok;

import '../actions/types.dart';
import '../commands/command_stack.dart';
import '../components/focusable_region.dart';
import '../components/locale_switcher.dart';
import '../components/panel_header.dart';
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
import 'layout_canvas.dart';
import 'widget_breadcrumb.dart';

part "editor.command.g.dart";

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
  String hello(String message) {
    print(message);
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
  bool single;

  // constructor

  User({required this.name, required this.address, required this.age, required this.single});

  // methods

  @Inject()
  String hello(String message) {
    print(message);
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
      single: true,
      address: Address(
          city: "Cologne",
          street: "Neumarkt"
      ));

  // methods

  @Inject()
  void setup() {
    print("setup");
  }

  @Method()
  void hello(String message) {
    print(message);
  }
}

class EditContext {
  // instance data

  ClassDesc? type;

  // constructor

  EditContext({required this.type});
}

// the overall screen, that combines all aspects
class EditorScreen extends StatefulWidget {
  // instance data

  List<WidgetData> models = [ContainerWidgetData()];

  // constructor

  EditorScreen({super.key});

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
  String path = "";
  String lastContent = "";
  ClassRegistry registry = ClassRegistry();
  ClassDesc? clazz;

  late final LocaleManager localeManager;
  SettingsManager settings = SettingsManager();

  // internal

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            const Text("Error"),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> loadRegistry(String path) async {
    var json = "";
    if (path.startsWith("assets:")) {
      json = await rootBundle.loadString(path.replaceFirst(":", "/"));
    }
    else {
      final file = File(path);

      try {
        json = await file.readAsString();
      }
      catch(e) {
        print(e);
        showErrorDialog(context, e.toString());
        return ;
      }
    }

    try {
      settings.set("registry", path);
      settings.flush();

      var registry = ClassRegistry()..read(jsonDecode(json)["classes"]);

      selectRegistry(registry);
    }
    catch(e) {
      print(e);
      showErrorDialog(context, e.toString());
    }
  }

  void selectClass(ClassDesc? clazz) {
    this.clazz = clazz;

    settings.set("class", clazz!.name);
    settings.flush();

    setState(() {
    });
  }

  void selectRegistry(ClassRegistry registry) {
    this.registry = registry;

    setState(() {

    });
  }

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

  String message(Exception e) {
    var message = e.toString();

    var index = message.indexOf(":");
    if (index >= 0)
      return message.substring(index + 1);
    else
      return message;
  }

  bool validate() {
    var root = widget.models[0];

    try {
      environment.get<WidgetValidator>().validate(root,
          type: clazz!,
          environment: environment
      );

      return true;
    }
    on ValidationException catch (e) {
      environment.get<MessageBus>().publish("messages", MessageEvent(
          source: this,
          type: MessageEventType.set,
          messages: e.errors.map((error) =>  Message(
              type: MessageType.error,
              widget: error.widget,
              property: error.property,
              message: message(error.exception)
          )).toList()
      ));

      return false;
    }
  }

  Future<bool> showUnsavedChangesDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // force the user to choose
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // cancel / keep editing
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // discard changes
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void showToast(String msg, {ok.ToastPosition? position}) {
    ok.showToastWidget(
        Padding(
          padding: const EdgeInsets.only(bottom: 32, right: 24), // margin from edges
          child: Container(
            constraints: BoxConstraints(
              minWidth: 200, // minimum width
              maxWidth: 400, // optional maximum width
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    msg,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
        ),
        ),
      duration: const Duration(seconds: 2),
      position: position ?? ok.ToastPosition(align: Alignment.bottomRight),
      dismissOtherToast: false,
      //backgroundColor: Colors.grey,
      //radius: 8.0,
      //textPadding: const EdgeInsets.all(12),
    );
  }

  void test() async { // TODO TEST CODE
    await loadRegistry("assets:main.types.g.json");

    selectClass(registry.getClass("Page"));
    await loadFile("assets:screen.json");
  }

  Future<void> loadFile(String path) async {
    var json = "";
    if (path.startsWith("assets:")) {
      json = await rootBundle.loadString(path.replaceFirst(":", "/"));
    }
    else {
      final file = File(this.path = path);

      try {
        json = await file.readAsString();

        settings.set("file", path);
        settings.flush();
      }
      catch (e) {
        showErrorDialog(context, e.toString());
      }
    }

    try {
      var root = JSON.deserialize<WidgetData>(jsonDecode(json));

      setState(() {
        widget.models = [root];

        updateCommandState();
      });
    }
    catch(e) {
      showErrorDialog(context, e.toString());
    }
  }

  Future<void> loadSettings() async {
    await settings.init();

    var registry = settings.get("registry", defaultValue: "");
    if (registry.isNotEmpty) {
      await loadRegistry(registry);

      var clazz = settings.get("class", defaultValue: "");

      if (clazz.isNotEmpty) {
        selectClass(this.registry.getClass(clazz));
      }
    }

    var file = settings.get("file", defaultValue: "");
    if (file.isNotEmpty) {
      await loadFile(file);
    }

    updateCommandState();
  }

  // commands

  @Command(i18n: "editor:commands.open", icon: Icons.folder_open)
  @override
  Future<void> _open() async {
    if (commandStack.isDirty()) {
      final discard = await showUnsavedChangesDialog(context);
      if (!discard) return; // user canceled
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      loadFile(result.files.single.path!);
    }
  }

  @Command(i18n: "editor:commands.new", name: "new", icon: Icons.note_add)
  @override
  Future<void> _newFile() async {
    if (commandStack.isDirty()) {
      final discard = await showUnsavedChangesDialog(context);
      if (!discard) return; // user canceled
    }

    commandStack.clear();

    widget.models = [ContainerWidgetData()];

    updateCommandState();
  }

  @Command(i18n: "editor:commands.save", icon: Icons.save)
  @override
  Future<void> _save() async {
    if ( path.isNotEmpty) {
      if (validate()) {
        var root = widget.models[0];

        var map = JSON.serialize(root);
        var str = jsonEncode(map);

        final file = File(path);

        // Write JSON string to file

        await file.writeAsString(str);

        ok.showToast("Saved");

        commandStack.clear();

        updateCommandState();
      } // if
    }
  }

  @Command(i18n: "editor:commands.revert", icon: Icons.restore)
  @override
  void _revert() {
    while ( commandStack.isDirty())
      commandStack.undo(silent: true);

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
    if (validate()) {
      setState(() { edit = !edit; });
    }
  }

  // override

  @override
  void updateCommandState() {
    setCommandEnabled("play", true);
    setCommandEnabled("new", true);
    setCommandEnabled("open", true);
    setCommandEnabled("save", commandStack.isDirty());
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
      loadSettings();

      bus.publish("load", LoadEvent(widget: widget.models.first, source: this));
    });



    updateCommandState();

    // TEST

    test();
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentProvider(
      environment: environment,
      child: Provider<EditContext>.value(
          value: EditContext(type: clazz),
          child: ok.OKToast( child: FocusScope(
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

                          LocaleSwitcher(
                            currentLocale: Provider.of<LocaleManager>(context).locale.languageCode,
                            supportedLocales: Provider.of<LocaleManager>(context).supportedLocales.map((loc) => loc.toString()) ,
                            onLocaleChanged: (locale) {
                              // Update your app locale
                              Provider.of<LocaleManager>(context).locale = Locale(locale);
                            },
                          ),

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
                              //create: (onClose) => FocusableRegion(child: WidgetTreePanel(models: widget.models, onClose: onClose)),
                              create: (onClose) => FocusGroup(
                                onActiveChanged: (isActive) {
                                  print("tree.active = $isActive");
                                  // Optionally inform your global state, e.g. via MessageBus
                                },
                                builder: (context, isActive) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    color: isActive
                                        ? Colors.blue.withOpacity(0.08)
                                        : Colors.transparent,
                                    child: WidgetTreePanel(models: widget.models, onClose: onClose, isActive: isActive)
                                      //isActive: isActive,
                                      // Tree continues to handle keyboard events internally
                                    );

                                },
                              ),

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
                            ),
                            Panel(
                                name: 'settings',
                                label: 'editor:docks.settings.label'.tr(),
                                tooltip: 'editor:docks.settings.tooltip'.tr(),
                                create: (onClose) =>  PanelContainer(
                                      title: "editor:docks.settings.label".tr(),
                                      onClose: onClose,
                                      child: SettingsPanel(editor: this)),
                                icon: Icons.settings
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
                            child: FocusGroup(
                            onActiveChanged: (isActive) {
                              print("canvas.active = $isActive");
                      // Optionally inform your global state, e.g. via MessageBus
                      },
                        builder: (context, isActive) {
                          return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              color: isActive
                                  ? Colors.blue.withOpacity(0.08)
                                  : Colors.transparent,
                              child: LayoutCanvas(
                                child: edit ?
                                EditorCanvas(
                                  messageBus: environment.get<MessageBus>(),
                                  models: widget.models,
                                  isActive: isActive,
                                  typeRegistry: environment.get<TypeRegistry>(),
                                ) :

                                WidgetContainer(
                                  instance:  environment.get<Page>(), // TODO
                                  widget: widget.models[0]
                                ),
                              )
                            //isActive: isActive,
                            // Tree continues to handle keyboard events internally
                          );

                        },
                      )
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
                            )
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
      )
    );
  }
}