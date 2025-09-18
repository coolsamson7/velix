import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sample/services/services.dart';
import 'package:velix_di/velix_di.dart';
import 'package:velix_i18n/velix_i18n.dart';

import '../editor/provider/environment_provider.dart';
import 'test_page.dart';
import 'todo_home_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // static

  static final List<Widget> _pages = <Widget>[
    TodoHomePage(),
    TestPage()
  ];

  // instance data

  int _selectedIndex = 0;
  Environment? environment;

  // public

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // override

  @override
  void dispose() {
    super.dispose();

    environment?.destroy();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleManager>();

    environment ??= Environment(parent: EnvironmentProvider.of(context));

    environment?.get<PerWidgetState>();

    return EnvironmentProvider(
      environment: environment!,
      child: Stack(
        children: [
          CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('example:main.todos'.tr()),
            ),
            child: SafeArea(
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CupertinoTabBar(
              currentIndex: _selectedIndex,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.list_bullet),
                  label: 'example:main.todos'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings),
                  label: 'example:main.settings'.tr(),
                ),
              ],
              onTap: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
