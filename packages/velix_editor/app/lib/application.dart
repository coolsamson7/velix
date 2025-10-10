import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/editor/editor.dart';
import 'package:velix_editor/metadata/type_registry.dart';

import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_ui/velix_ui.dart';

import 'package:provider/provider.dart';


class EditorApp extends StatelessWidget {
  // instance data

  final I18N i18n;
  final LocaleManager localeManager;
  final Environment environment;

  // constructor

  const EditorApp({super.key, required this.i18n, required this.localeManager, required this.environment});

  // override

  @override
  Widget build(BuildContext context) {
    i18n.addListenerAsync((state) =>
        environment.get<TypeRegistry>().changedLocale(localeManager.locale)
    );

    return ChangeNotifierProvider.value(
        value: i18n,
        child: EnvironmentProvider(
            environment: environment,
            child:  MultiProvider(
                providers: [
                  ChangeNotifierProvider<LocaleManager>(create: (_) => localeManager),
                  Provider<CommandManager>(create: (_) => CommandManager(
                      interceptors: [
                        LockCommandInterceptor(),
                        TracingCommandInterceptor()
                      ]
                  )),
                ],
                child: Consumer<I18N>(
                    builder: (BuildContext context, I18N value, Widget? child) {
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
                            body: EditorScreen()
                        ),
                      );
                    }
                )
            )
        )
    );
  }
}