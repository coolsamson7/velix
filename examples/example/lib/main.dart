import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:velix/velix.dart' hide Property;
import 'package:velix_di/velix_di.dart';
import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';
import 'package:velix_ui/velix_ui.dart';
import 'package:provider/provider.dart';

import 'main.types.g.dart';
import 'providers/todo_provider.dart';
import 'screens/main_screen.dart';

/// Custom Translator
class EasyLocalizationTranslator extends Translator {
  EasyLocalizationTranslator() {
    Translator.instance = this;
  }

  @override
  String translate(String key, {String? defaultValue, Map<String, dynamic> args = const {}}) {
    return I18N.tr(key, defaultValue: defaultValue, args: args);
  }
}

/// Application module
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
  WidgetsFlutterBinding.ensureInitialized();

  // bootstrap Velix
  Velix.bootstrap;

  // JSON setup
  JSON(
    validate: false,
    converters: [
      Convert<DateTime,String>(
        convertSource: (value) => value.toIso8601String(),
        convertTarget: (str) => DateTime.parse(str),
      )
    ],
    factories: [Enum2StringFactory()],
  );

  TypeViolationTranslationProvider();
  registerTypes();
  ValuedWidget.platform = TargetPlatform.iOS;

  // Tracing
  Tracer(
    isEnabled: true,
    trace: ConsoleTrace("%d [%l] %p: %m [%f]"),
    paths: {
      "": TraceLevel.off,
      "i18n": TraceLevel.full,
      "di": TraceLevel.full
    },
  );

  // I18N setup
  final localeManager = LocaleManager(
    const Locale('en', "EN"),
    supportedLocales: const [Locale('en', "EN"), Locale('de', "DE")],
  );

  final i18n = I18N(
    fallbackLocale: const Locale("en", "EN"),
    localeManager: localeManager,
    loader: AssetTranslationLoader(
      namespacePackageMap: {
        "validation": "velix",
      },
    ),
    missingKeyHandler: (key) => '##$key##',
    preloadNamespaces: ["validation", "example"],
  );

  // Run app with proper provider hierarchy
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeManager),
        ChangeNotifierProvider(
          create: (_) => Environment(forModule: ApplicationModule).get<TodoProvider>(),
        ),
        Provider<CommandManager>(
          create: (_) => CommandManager(
            interceptors: [
              LockCommandInterceptor(),
              TracingCommandInterceptor(),
            ],
          ),
        ),
        Provider<Environment>(
          create: (_) => Environment(forModule: ApplicationModule),
        ),
      ],
      child: TODOApp(i18n: i18n),
    ),
  );
}

/// Main TODO App
class TODOApp extends StatelessWidget {
  final I18N i18n;

  const TODOApp({super.key, required this.i18n});

  @override
  Widget build(BuildContext context) {
    final localeManager = context.watch<LocaleManager>();
    final environment = context.read<Environment>();

    return EnvironmentProvider(
      environment: environment,
      child: MaterialApp(
        title: 'TODO',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
        ),
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: localeManager.supportedLocales,
        locale: localeManager.locale,
        home: const MainScreen(),
      ),
    );
  }
}
