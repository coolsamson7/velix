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
      i18n: 'main.addTodo1',
      icon: CupertinoIcons.add,
      lock: LockType.view,
    );
    addCommand(
      "removeTodo",
      _removeTodo,
      i18n: 'main.removeTodo',
      icon: CupertinoIcons.delete,
    );
    addCommand("toggleTodo", _toggleTodo, i18n: 'main.toggleTodo');
  }

  // command declarations

  Future<Todo> _addTodo();
  void _removeTodo(String id);
  void _toggleTodo(String id);

  // command bodies

  Future<Todo> addTodo() async {
    return await execute("addTodo", []);
  }

  void removeTodo(String id) {
    execute("removeTodo", [id]);
  }

  void toggleTodo(String id) {
    execute("toggleTodo", [id]);
  }
}
