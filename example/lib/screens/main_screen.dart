import 'package:flutter/cupertino.dart';
import 'package:velix/i18n/locale.dart';
import 'todo_home_page.dart';
import 'test_page.dart';
import 'package:velix/i18n/i18n.dart';
import 'package:provider/provider.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    TodoHomePage(),
    TestPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleManager>();

    return Stack(
      children: [
        CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('example:main.todos'.tr()),
          ),
          child: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
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
                label:  'example:main.todos'.tr(),
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
    );
  }
}