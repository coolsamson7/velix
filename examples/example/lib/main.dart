import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_di/velix_di.dart';
import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';
import 'package:velix_ui/velix_ui.dart';

import 'package:provider/provider.dart';
import 'main.type_registry.g.dart';
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

class EnvironmentProvider extends InheritedWidget {
  final Environment environment;

  const EnvironmentProvider({
    Key? key,
    required this.environment,
    required Widget child,
  }) : super(key: key, child: child);

  static Environment of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<EnvironmentProvider>();
    return provider!.environment;
  }

  @override
  bool updateShouldNotify(EnvironmentProvider oldWidget) {
    return environment != oldWidget.environment;
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

  registerAllDescriptors();
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

  // load namespaces

  runApp(
    ChangeNotifierProvider.value(
      value: localeManager,
      child: TODOApp(i18n: i18n),
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
                ],
                translator: EasyLocalizationTranslator()
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