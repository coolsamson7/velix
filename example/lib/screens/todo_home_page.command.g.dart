// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'todo_home_page.dart';

mixin _TodoHomePageStateCommands on CommandController<TodoHomePage> {
  // override

  @override
  void initCommands() {
    addCommand(
      "addTodo",
      _addTodo,
      i18n: 'example:main.addTodo',
      icon: CupertinoIcons.add,
      lock: LockType.view,
    );
    addCommand(
      "removeTodo",
      _removeTodo,
      i18n: 'example:main.removeTodo',
      icon: CupertinoIcons.delete,
    );
    addCommand("toggleTodo", _toggleTodo, i18n: 'example:main.toggleTodo');
    addCommand(
      "switchLocale",
      _switchLocale,
      i18n: 'example:main.switchLocale',
      icon: CupertinoIcons.globe,
    );
  }

  // command declarations

  Future<Todo> _addTodo();
  void _removeTodo(String id);
  void _toggleTodo(String id);
  void _switchLocale();

  // command bodies

  Future<Todo> addTodo() async {
    return await execute("addTodo", []);
  }

  void removeTodo(String id) {
    execute("removeTodo", []);
  }

  void toggleTodo(String id) {
    execute("toggleTodo", []);
  }

  void switchLocale() {
    execute("switchLocale", []);
  }
}
