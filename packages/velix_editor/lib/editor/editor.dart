import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:file_selector/file_selector.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart' as ok show OKToast;
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/components/toast.dart';
import 'package:velix_editor/editor/settings.dart';
import 'package:velix_editor/editor/settings_panel.dart';
import 'package:velix_editor/editor/test_model.dart';
import 'package:velix_editor/metadata/widgets/container.dart';
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_mapper/mapper/json.dart';

import 'package:velix_ui/provider/environment_provider.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_i18n/i18n/locale.dart';
import 'package:velix_ui/commands/command.dart';

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

class EditContext {
  // instance data

  ClassDesc? type;

  // constructor

  EditContext({required this.type});
}

// the overall screen, that combines all aspects
class EditorScreen extends StatefulWidget {
  // instance data

  final I18N i18n;
  final Environment environment;

  // constructor

  EditorScreen({super.key, required this.i18n, required this.environment});

  // override

  @override
  State<EditorScreen> createState() => EditorScreenState();
}

class EditorScreenState extends State<EditorScreen> with CommandController<EditorScreen>, EditorScreenStateCommands, TickerProviderStateMixin, StatefulMixin<EditorScreen>  {
  // instance data

  Environment? _environment;
  CommandStack? _commandStack;
  LocaleManager? _localeManager;
  bool edit = true;
  String registryPath = "";
  String path = "";
  String lastContent = "";
  ClassRegistry registry = ClassRegistry();
  ClassDesc? clazz;
  List<WidgetData> models = [ContainerWidgetData()];

  late SettingsManager settings;

  Environment get environment => _environment ??= Environment(parent: EnvironmentProvider.of(context));
  LocaleManager get localeManager => _localeManager ??=  Provider.of<LocaleManager>(context, listen: false);
  CommandStack get commandStack => _commandStack ??=  environment.get<CommandStack>();

  @override
  String get stateName => "editor";

  // override

  @override
  Future<void> apply(Map<String,dynamic> data) async {
    String registry = data["registry"] ?? "";
    if ( registry.isNotEmpty) {
      await loadRegistry(registry);

      String clazz = data["class"] ?? "";
      if ( clazz.isNotEmpty)
        selectClass(this.registry.getClass(clazz));
    }

    String file = data["file"] ?? "";
    if ( file.isNotEmpty)
      await loadFile(file);

  }

  @override
  Future<void> write(Map<String,dynamic> data) async {
    data["registry"] = registryPath;
    data["file"] = path;
    data["class"] = clazz?.name ?? "";
  }

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
      //settings.set("registry", path);
      //settings.flush();

      var registry = ClassRegistry()..read(jsonDecode(json)["classes"]);

      registryPath = path;

      selectRegistry(registry);

      flushSettings();
    }
    catch(e) {
      print(e);
      showErrorDialog(context, e.toString());
    }
  }

  void selectClass(ClassDesc? clazz) {
    this.clazz = clazz;

    flushSettings();

    //settings.set("class", clazz!.name);
    //settings.flush();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      localeManager.locale = Locale(locale);
    });
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
    var root = models[0];

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

  void test() async { // TODO TEST CODE
    await loadRegistry("assets:main.types.g.json");

    selectClass(registry.getClass("TestPage"));
    await loadFile("assets:screen.json");

    setState(() {
      environment.get<MessageBus>().publish("load", LoadEvent(widget: models.first, source: this));
    });


    writeSettings();

    flushSettings();
  }

  Future<void> loadFile(String path) async {
    var json = "";
    if (path.startsWith("assets:")) {
      json = await rootBundle.loadString(path.replaceFirst(":", "/"));
    }
    else {
      final file = File(path);

      try {
        json = await file.readAsString();

        //settings.set("file", path);
      }
      catch (e) {
        showErrorDialog(context, e.toString());
      }
    }

    try {
      var root = JSON.deserialize<WidgetData>(jsonDecode(json));

      this.path = path;

      writeSettings(); // ?? TODO
      flushSettings();

      setState(() {
        models = [root];

        environment.get<MessageBus>().publish("load", LoadEvent(widget: root, source: this));
        environment.get<MessageBus>().publish("selection", SelectionEvent(selection: null, source: this));

        showInfoToast("loaded $path");
        updateCommandState();
      });
    }
    catch(e) {
      showErrorDialog(context, e.toString());
    }
  }

  Future<void> loadSettings() async {
    state = settings.getSettings(stateName);

    applySettings();

    /*var registry = settings.get("registry", defaultValue: "");
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
    }*/
  }

  String pathTitle() {
    if (path.isNotEmpty) {
      if ( path.contains("/"))
        return p.basenameWithoutExtension(path);
      else
        return path;
    }
    else return "- new -";
  }

  String pathTooltip() {
    if (path.isNotEmpty)
      return path;
    else
      return "new widget";
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

  @Command(i18n: "editor:commands.new", name: "new", icon: Icons.post_add) // note_add
  @override
  Future<void> _newFile() async {
    if (commandStack.isDirty()) {
      final discard = await showUnsavedChangesDialog(context);
      if (!discard) return; // user canceled
    }

    commandStack.clear();

    models = [ContainerWidgetData()];

    path = "";
    environment.get<MessageBus>().publish("load", LoadEvent(widget:models[0], source: this));

    setState(() {

    });

    updateCommandState();
  }

  @Command(i18n: "editor:commands.save", icon: Icons.save)
  @override
  Future<void> _save() async {
    if (path.isEmpty) {
      final typeGroup = XTypeGroup(label: 'text', extensions: ['json']);
      final file = await FileSelectorPlatform.instance.getSavePath(suggestedName: 'untitled.txt', acceptedTypeGroups: [typeGroup]);

      if (file == null)
        return;

        path = file;
    }

    if ( path.isNotEmpty) {
      if (validate()) {
        var root = models[0];

        var map = JSON.serialize(root);
        var str = jsonEncode(map);

        final file = File(path);

        // Write JSON string to file

        await file.writeAsString(str);

        showInfoToast("Saved $path");

        setState(() {

        });

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
  void initState() {
    super.initState();

    widget.i18n.addListenerAsync((state) {
     updateI18N();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //loadSettings();

      //TODO fuck zu oft!

      environment.get<MessageBus>().publish("load", LoadEvent(widget: models.first, source: this));

      setState(() {

      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // create

    commandStack.addListener(() => setState(() {
      updateCommandState();
    }));

    updateCommandState();

    // TODO TEST

    //test();
  }

  @override
  Widget build(BuildContext context) {
    //final localeManager = context.watch<LocaleManager>();

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
                          button("new"),
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
                            currentLocale: localeManager.locale.languageCode,
                            supportedLocales: localeManager.supportedLocales.map((loc) => loc.toString()) ,
                            onLocaleChanged: (locale) {
                              // Update your app locale
                             switchLocale(locale);
                            },
                          )
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
                                    child: WidgetTreePanel(models: models, onClose: onClose, isActive: isActive)
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
                                create: (onClose) => JsonEditorPanel(model: models.first, onClose: onClose),
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
                                icon: Icons.forum_outlined , // chat_bubble_outline, report
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
                          return PanelContainer(
                              title: pathTitle(),
                              tooltip:  pathTooltip(),
                              child: LayoutCanvas(
                                child: edit ?
                                EditorCanvas(
                                  messageBus: environment.get<MessageBus>(),
                                  models: models,
                                  isActive: isActive,
                                  typeRegistry: environment.get<TypeRegistry>(),
                                ) :

                                WidgetContainer(
                                  instance:  environment.get<TestPage>(), // TODO
                                  widget: models[0]
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