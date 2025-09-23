import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/editor/editor.dart';
import 'package:velix_editor/metadata/type_registry.dart';

import 'package:velix_editor/metadata/widget_data.dart';
import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_ui/velix_ui.dart';

import 'package:provider/provider.dart';


class EditorApp extends StatelessWidget {
  // instance data

  final I18N i18n;
  final LocaleManager localeManager;
  final Environment environment;
  final List<WidgetData> widgets;

  // constructor

  const EditorApp({super.key, required this.i18n, required this.localeManager, required this.environment, required this.widgets});

  // override

  @override
  Widget build(BuildContext context) {
    localeManager.addListener(() =>
        environment.get<TypeRegistry>().changedLocale(localeManager.locale)
    );

    return ChangeNotifierProvider.value(
        value: localeManager,
        child: EnvironmentProvider(
            environment: environment,
            child:  MultiProvider(
                providers: [
                  Provider<CommandManager>(create: (_) => CommandManager(
                      interceptors: [
                        LockCommandInterceptor(),
                        TracingCommandInterceptor()
                      ]
                  )),
                ],
                child: Consumer<LocaleManager>(
                    builder: (BuildContext context, LocaleManager value, Widget? child) {
                      return MaterialApp(
                        title: 'Editor',

                        theme: ThemeData(
                          brightness: Brightness.light,
                          primaryColor: Colors.blue
                        ),

                        // localization

                        localizationsDelegates: [
                          I18nDelegate(i18n: i18n),

                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                        ],
                        supportedLocales: localeManager.supportedLocales,
                        locale: localeManager.locale,

                        // main screen

                        home: Scaffold(
                            body: EditorScreen(models: widgets)
                        ),
                      );
                    }
                )
            )
        )
    );
  }
}