import 'package:flutter/cupertino.dart';

import 'package:velix/velix.dart';

import 'package:provider/provider.dart';
import 'service_locator.dart';
import 'providers/todo_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  configureDependencies();

  registerAllDescriptors();
  registerWidgets();

  //WidgetsFlutterBinding.ensureInitialized();

  //await EasyLocalization.ensureInitialized();

  getIt.registerSingleton<CommandManager>(
      CommandManager(interceptors: [LockCommandInterceptor(), TracingCommandInterceptor()])
  );

  runApp(const MyApp());
  /*runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('de')],
      path: 'assets/translations', // folder path
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );*/
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<TodoProvider>()),
        Provider<CommandManager>(create: (_) => CommandManager(
          interceptors: [
            LockCommandInterceptor(),
            TracingCommandInterceptor()
          ]
        )),
      ],
      child: CupertinoApp(
        title: 'TODO App',
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
        //localizationsDelegates: context.localizationDelegates,
        //supportedLocales: context.supportedLocales,
        //locale: context.locale,
        home: const MainScreen(),
      ),
    );
  }
}