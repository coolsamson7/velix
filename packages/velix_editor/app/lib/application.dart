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

class MyWindowListener extends WindowListener {
  EditorAppState state;

  MyWindowListener({required this.state});

  // override

  @override
  void onWindowClose() async {
    state.writeSettings();
    await state.flushSettings();

    // done

    await windowManager.destroy();
  }
}

class EditorAppState extends State<EditorApp> with StatefulMixin {
  @override
  String get stateName => "editorApp";

  Rect? windowRect;

  // constructor

  EditorAppState() {
    windowManager.addListener(MyWindowListener(state: this));
  }
  // override

  @override
  Future<void> apply(Map<String, dynamic> data) async {
    // Restore locale
    final savedLocale = data["locale"];
    if (savedLocale != null && savedLocale is String) {
      widget.localeManager.locale = Locale(savedLocale);
    }

    // Restore window position
    final x = data["window_x"];
    final y = data["window_y"];
    final width = data["window_width"];
    final height = data["window_height"];
    if (x != null && y != null && width != null && height != null) {
      windowRect = Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());

      // Optionally, use desktop window API to set window bounds

      await windowManager.setBounds(windowRect!);
    }
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    // Save locale
    data["locale"] = widget.localeManager.locale.languageCode;

    // Save window position
    // For desktop: you can get real window bounds from window_manager
    if (windowRect != null) {
      data["window_x"] = windowRect!.left;
      data["window_y"] = windowRect!.top;
      data["window_width"] = windowRect!.width;
      data["window_height"] = windowRect!.height;
    } else {
      // fallback: screen size
      final size = WidgetsBinding.instance.window.physicalSize;
      data["window_x"] = 0;
      data["window_y"] = 0;
      data["window_width"] = size.width;
      data["window_height"] = size.height;
    }
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