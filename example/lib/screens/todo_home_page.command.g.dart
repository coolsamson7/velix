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
    addCommand("addTodo", _addTodo, i18n: 'main.addTodo', lock: LockType.view);
    addCommand("removeTodo", _removeTodo, i18n: 'main.removeTodo');
    addCommand("toggleTodo", _toggleTodo, i18n: 'main.toggleTodo');
  }

  // command declarations

  void _addTodo();
  void _removeTodo(String id);
  void _toggleTodo(String id);

  // command bodies

  void addTodo() {
    execute("addTodo", []);
  }

  void removeTodo(String id) {
    execute("removeTodo", [id]);
  }

  void toggleTodo(String id) {
    execute("toggleTodo", [id]);
  }
}
