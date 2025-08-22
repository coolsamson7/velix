import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
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
  String translate(String key, {Map<String, String>  args = const {}}) {
    return key.tr(namedArgs: args);
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

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('de')],
      path: '.', // folder path!
      assetLoader: MultiAssetLoader(paths: [
        "assets/locales/example",
        "packages/velix/assets/locales/velix",
      ]),
      fallbackLocale: const Locale('en'),
      child: TODOApp(),
    ),
  );
}

class TODOApp extends StatelessWidget {
  const TODOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
      child: CupertinoApp(
        title: 'TODO',

        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
        ),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const MainScreen(),
      ),
    );
  }
}