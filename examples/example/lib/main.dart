import 'package:flutter/cupertino.dart' hide MetaData;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velix/velix.dart' hide Property;
import 'package:velix_di/velix_di.dart';
import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';
import 'package:velix_ui/velix_ui.dart';

import 'package:provider/provider.dart';
import 'editor/editor.dart';
import 'editor/editor/editor.dart';
import 'editor/metadata/type_registry.dart';
import 'editor/metadata/widgets/button.dart';
import 'editor/metadata/widgets/container.dart';
import 'editor/metadata/widgets/text.dart';
import 'editor/provider/environment_provider.dart';
import 'main.types.g.dart';
import 'providers/todo_provider.dart';
import 'screens/main_screen.dart';

class EasyLocalizationTranslator extends Translator {
  // constructor

  EasyLocalizationTranslator() {
    Translator.instance = this;
  }

  // implement

  @override
  String translate(String key, {Map<String, dynamic>  args = const {}}) {
    return I18N.instance.translate(key, args: args);
  }
}


@Module(imports: [])
class ApplicationModule {
  @OnInit()
  void onInit() {
    print("ServiceModule.onInit()");
  }

  @OnDestroy()
  void onDestroy() {
    print("ServiceModule.onDestroy()");
  }
}

void main() async {
  // bootstrap library

  Velix.bootstrap;

  // configure json stuff

  JSON(
      validate: false,
      converters: [Convert<DateTime,String>((value) => value.toIso8601String(), convertTarget: (str) => DateTime.parse(str))],
      factories: [Enum2StringFactory()]);

  TypeViolationTranslationProvider();

  registerTypes();
  registerWidgets(TargetPlatform.iOS);

  WidgetsFlutterBinding.ensureInitialized();

  Tracer(
      isEnabled: true,
      trace: ConsoleTrace("%d [%l] %p: %m [%f]"), // d(ate), l(evel), p(ath), m(message), f(ile)
      paths: {
        "": TraceLevel.off,
        "i18n": TraceLevel.full,
        "di": TraceLevel.full
      });

  var localeManager = LocaleManager(Locale('en', "EN"), supportedLocales: [Locale('en', "EN"), Locale('de', "DE")]);
  var i18n = I18N(
      fallbackLocale: Locale("en", "EN"),
      localeManager: localeManager,
      loader: AssetTranslationLoader(
        namespacePackageMap: {
          "validation": "velix"
        }
      ),
      missingKeyHandler: (key) => '##$key##',
      preloadNamespaces: ["validation", "example"]
  );

  // NEW

  //var meta = MetaData(name: "text", type: TextWidgetData, properties: [
  //  Property(name: "label", type: String)
  //]);

  //typeRegistry.register(meta);

  //typeRegistry.register(MetaData(
  //  name: "container",
  //  type: ContainerWidgetData,
  //  properties: [],
  //));


  // currently we do this manually, but we will use the code generator soon enough

  //runtimeTheme.widgets["text"] = TextWidgetBuilder();
  //runtimeTheme.widgets["container"] = ContainerWidgetBuilder();

  /*var textData = {
    "type": "container",
    "children": [
      {
        "type": "text",
        "label": "Hello World"
      },
      {
        "type": "text",
        "label": "Second Text"
      }
    ]
  };*/


  var widgetData = ContainerWidgetData(children: [
    TextWidgetData(label: "eins"),
    ButtonWidgetData(label: "zwei", number: 2, isCool: true),
    TextWidgetData(label: "zwei")
  ]);


  // NEW

  var environment = Environment(forModule: ApplicationModule);
  var typeRegistry = environment.get<TypeRegistry>();

  // load namespaces

  runApp(
    ChangeNotifierProvider.value(
      value: localeManager,
      //child: TODOApp(i18n: i18n),
      child:  EnvironmentProvider(
        environment: environment,
        child: MaterialApp(
            title: "Editor",
            home: Scaffold(
                body: EditorScreen(
                    models: [widgetData],
                    metadata: typeRegistry.metaData
                )
            )
        )
      )
    ),
  );
}

class TODOApp extends StatelessWidget {
  // instance data

  final I18N i18n;
  final Environment environment = Environment(forModule: ApplicationModule);
  
  // constructor
  
   TODOApp({super.key, required this.i18n});
  
  // override

  @override
  Widget build(BuildContext context) {
    final localeManager = context.watch<LocaleManager>();

    return EnvironmentProvider(
        environment: environment,
        child:  MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => environment.get<TodoProvider>()),
            Provider<CommandManager>(create: (_) => CommandManager(
                interceptors: [
                  LockCommandInterceptor(),
                  TracingCommandInterceptor()
                ]
            )),
          ],
          child: Consumer<LocaleManager>(
              builder: (BuildContext context, LocaleManager value, Widget? child) {
                return CupertinoApp(
                  title: 'TODO',

                  theme: const CupertinoThemeData(
                    brightness: Brightness.light,
                    primaryColor: CupertinoColors.activeBlue,
                  ),

                  // localization

                  localizationsDelegates: [I18nDelegate(i18n: i18n), GlobalCupertinoLocalizations.delegate,],//...context.localizationDelegates,
                  supportedLocales: localeManager.supportedLocales,
                  locale: localeManager.locale,

                  home: const MainScreen(),
                );
              }
          )
      )
    );
  }
}