import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/editor/editor.dart';
import 'package:velix_editor/editor/settings.dart';
import 'package:velix_editor/metadata/type_registry.dart';

import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_ui/velix_ui.dart';

import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class EditorApp extends StatefulWidget {
  final I18N i18n;
  final LocaleManager localeManager;
  final Environment environment;

  const EditorApp({
    super.key,
    required this.i18n,
    required this.localeManager,
    required this.environment,
  });

  @override
  State<EditorApp> createState() => EditorAppState();
}

class EditorWindowListener extends WindowListener {
  // instance data

  EditorAppState state;

  // constructor

  EditorWindowListener({required this.state});

  // override

  @override
  void onWindowResize() async {
    await state.flushSettings(write: true);
  }

  @override
  void onWindowMove() async {
    await state.flushSettings(write: true);
  }

  @override
  void onWindowMaximize() async {
    await state.flushSettings(write: true);
  }

  @override
  void onWindowUnmaximize() async {
    await state.flushSettings(write: true);
  }

  @override
  void onWindowClose() async {
    await state.flushSettings(write: true);

    // done

    await windowManager.destroy();
  }
}

class EditorAppState extends State<EditorApp> with StatefulMixin {
  // instance data

  @override
  String get stateName => "editorApp";

  // constructor

  EditorAppState() {
    windowManager.addListener(EditorWindowListener(state: this));
  }

  // override

  @override
  Future<void> apply(Map<String, dynamic> data) async {
    // Restore locale

    final savedLocale = data["locale"];
    if (savedLocale != null && savedLocale is String) {
      widget.localeManager.locale = Locale(savedLocale);
    }

    // restore window position

    Map<String,dynamic>? window = data["window"];
    if ( window != null) {
      var bounds = Rect.fromLTWH(window["x"], window["y"], window["width"], window["height"],);

      await windowManager.setBounds(bounds);

      var state = data["state"];
      switch (state) {
        case "normal":
          break;
        case "maximized":
          await windowManager.maximize();
          break;
        case "minimized":
          await windowManager.minimize();
          break;
        case "fullscreen":
          await windowManager.setFullScreen(true);
          break;
      }
    }
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    // Save locale

    data["locale"] = widget.localeManager.locale.languageCode;

    // window

    var state = "normal";

    final bool isMaximized = await windowManager.isMaximized();
    if ( isMaximized )
      state = "maximized";

    final bool isMinimized = await windowManager.isMinimized();
    if ( isMinimized )
      state = "minimized";

    final bool isFullScreen = await windowManager.isFullScreen();
    if ( isFullScreen )
      state = "fullscreen";

    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();

    data["window"] = {
      "x": pos.dx,
      "y": pos.dy,
      "width": size.width,
      "height": size.height,
      "state": state
    };
  }

  @override
  void initState() {
    //settings = environment.get<SettingsManager>();

    state = widget.environment.get<SettingsManager>().getSettings(stateName); // is already loaded

    super.initState();

    widget.i18n.addListenerAsync((state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.environment.get<TypeRegistry>().changedLocale(widget.localeManager.locale);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.i18n,
      child: EnvironmentProvider(
        environment: widget.environment,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleManager>(
              create: (_) => widget.localeManager,
            ),
            Provider<CommandManager>(
              create: (_) => CommandManager(
                interceptors: [
                  LockCommandInterceptor(),
                  TracingCommandInterceptor(),
                ],
              ),
            ),
          ],
          child: Consumer<I18N>(
            builder: (BuildContext context, I18N value, Widget? child) {
              return MaterialApp(
                title: 'Editor',
                theme: ThemeData(
                  brightness: Brightness.light,
                  primaryColor: Colors.blue,
                ),
                localizationsDelegates: [
                  I18nDelegate(i18n: widget.i18n),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: widget.localeManager.supportedLocales,
                locale: widget.localeManager.locale,
                home: Scaffold(
                  body: EditorScreen(
                    i18n: widget.i18n,
                    environment: widget.environment,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    writeSettings(); // save locale + window
    flushSettings(); // persist

    super.dispose();
  }
}