import 'package:editor_sample/main.types.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velix/velix.dart' hide Property;
import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/editor/editor.dart';
import 'package:velix_editor/editor_module.dart';
import 'package:velix_editor/metadata/properties/properties.dart';

import 'package:velix_editor/metadata/widget_data.dart';
import 'package:velix_editor/metadata/widgets/button.dart';
import 'package:velix_editor/metadata/widgets/container.dart';
import 'package:velix_editor/metadata/widgets/label.dart';
import 'package:velix_editor/metadata/widgets/text.dart';
import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';
import 'package:velix_ui/velix_ui.dart';

import 'package:provider/provider.dart';


class VelixTranslator extends Translator {
  // constructor

  VelixTranslator() {
    Translator.instance = this;
  }

  // implement

  @override
  String translate(String key, {Map<String, dynamic>  args = const {}}) {
    return I18N.instance.translate(key, args: args);
  }
}

@Module(imports: [EditorModule])
class ApplicationModule {
}

void main() async {
  // flutter

  registerWidgets(TargetPlatform.iOS);

  WidgetsFlutterBinding.ensureInitialized();

  // tracer

  Tracer(
      isEnabled: true,
      trace: ConsoleTrace("%d [%l] %p: %m [%f]"), // d(ate), l(evel), p(ath), m(message), f(ile)
      paths: {
        "": TraceLevel.off,
        "i18n": TraceLevel.full,
        "editor": TraceLevel.full,
        "di": TraceLevel.full
      });

  // bootstrap types

  Velix.bootstrap;
  EditorModule.boot; // this sucks

  registerTypes();

  // configure json stuff

  JSON(
      validate: false,
      converters: [Convert<DateTime,String>(convertSource: (value) => value.toIso8601String(), convertTarget: (str) => DateTime.parse(str))],
      factories: [Enum2StringFactory()]);

  // translation

  TypeViolationTranslationProvider();

  var localeManager = LocaleManager(Locale('en', "EN"), supportedLocales: [Locale('en', "EN"), Locale('de', "DE")]);
  var i18n = I18N(
      fallbackLocale: Locale("en", "EN"),
      localeManager: localeManager,
      loader: AssetTranslationLoader(
        namespacePackageMap: {
          "validation": "velix",
          "editor": "velix_editor"
        }
      ),
      missingKeyHandler: (key) => '##$key##',
      preloadNamespaces: ["validation", "example", "editor"]
  );

  var json = {
    "type": "container",
    "children": [
      {
        "type": "text",
        "children": [],
        "label": "Hello World"
      },
      {
        "type": "button",
        "children": [],
        "number": 1,
        "isCool": true
      },
      {
        "type": "text",
        "children": [],
        "label": "Second Text"
      }
    ]
  };

  //var widget = JSON.deserialize<WidgetData>(json); // TEST TODO */

  var widgets = ContainerWidgetData(children: [
    TextWidgetData(label: "eins"),
    ButtonWidgetData(label: "zwei", font: Font(weight: FontWeight.normal, style: FontStyle.normal, size: 16)),
    LabelWidgetData(label: "zwei", font: Font(weight: FontWeight.normal, style: FontStyle.normal, size: 16)),
    TextWidgetData(label: "zwei"),
    ContainerWidgetData(children: [
      TextWidgetData(label: "drei"),
      TextWidgetData(label: "vier"),
    ])
  ]);


  // boot environment

  var environment = Environment(forModule: ApplicationModule);

  // load namespaces

  runApp(EditorApp(environment: environment, i18n: i18n, localeManager: localeManager, widgets: [widgets]));
}

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
    //final localeManager = context.watch<LocaleManager>();

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

                    //theme: const CupertinoThemeData(
                    //  brightness: Brightness.light,
                    //  primaryColor: CupertinoColors.activeBlue,
                    //),

                    // localization

                    localizationsDelegates: [I18nDelegate(i18n: i18n), GlobalCupertinoLocalizations.delegate,],//...context.localizationDelegates,
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