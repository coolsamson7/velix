import 'package:flutter/cupertino.dart';
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
      path: 'assets/translations', // folder path!
      fallbackLocale: const Locale('en'),
      child: const TODOApp(),
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