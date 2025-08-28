import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sample/services/services.dart';
import 'package:velix/velix.dart';

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


class MultiAssetLoader extends AssetLoader {
  // instance data

  final List<String> paths;

  // constructor

  MultiAssetLoader({required this.paths});

  // override

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    Map<String, dynamic> translations = {};

    for (final basePath in paths) {
      try {
        // Determine the full path based on locale folder + filename
        late String file;

        // Split the last segment of basePath as filename

        final segments = basePath.split('/');
        final fileName = segments.last; // e.g. 'example.json' or 'velix.json'
        final dirPath = segments.sublist(0, segments.length - 1).join('/');

        file = '$dirPath/${locale.languageCode}/$fileName.json';


        final jsonStr = await rootBundle.loadString(file);
        final Map<String, dynamic> jsonMap = json.decode(jsonStr);

        translations.addAll(jsonMap); // Merge
      }
      catch (e) {
        // Ignore missing files
        print(e);
      }
    }

    return translations;
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



void main() async {
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
  final Environment environment = Environment(ServiceModule);
  
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
            ChangeNotifierProvider(create: (_) => TodoProvider()),
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