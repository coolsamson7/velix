// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'todo_home_page.dart';

mixin _$_TodoHomePageStateCommands on CommandController<TodoHomePage> {
  @override
  void initCommands() {
    addCommand("addTodo", _addTodo);
    addCommand("removeTodo", _removeTodo);
    addCommand("toggleTodo", _toggleTodo);
  }

  void addTodo() {
    execute("addTodo", []);
  }

  void _addTodo();
  void removeTodo(String id) {
    execute("removeTodo", [id]);
  }

  void _removeTodo(String id);
  void toggleTodo(String id) {
    execute("toggleTodo", [id]);
  }

  void _toggleTodo(String id);
}
