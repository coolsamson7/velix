// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'todo_provider.dart';

mixin _$TodoProviderCommands on CommandController {
  void initCommands() {
    addCommand("addTodo", _addTodo);
    addCommand("toggleTodo", _toggleTodo);
    addCommand("removeTodo", _removeTodo);
  }

  void addTodo(String title) {
    execute("addTodo", [title]);
  }

  void _addTodo(String title);
  void toggleTodo(String id) {
    execute("toggleTodo", [id]);
  }

  void _toggleTodo(String id);
  void removeTodo(String id) {
    execute("removeTodo", [id]);
  }

  void _removeTodo(String id);
}
