import 'package:flutter/material.dart';
import 'package:velix/velix.dart';
import '../models/todo.dart';
import 'package:injectable/injectable.dart';

part 'todo_provider.command.g.dart';

@lazySingleton
class TodoProvider with CommandController, ChangeNotifier,  _$TodoProviderCommands {
  final List<Todo> _todos = [];

  TodoProvider() {
    initCommands();
  }

  List<Todo> get todos => _todos;

  @Command()
  @override
  void _addTodo(String title) async {
    Todo todo = Todo(id: DateTime.now().toString(), details: Details(author: "", priority: 1), title: title);

    //String id = TypeDescriptor.forType(Todo).get(todo, "id");
    //Map json = serializeToJson(todo);

    _todos.add(todo);

    notifyListeners(); 
  }

  @override
  @Command()
  void _toggleTodo(String id) {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.completed = !todo.completed;

    notifyListeners();
  }

  @Command()
  @override
  void _removeTodo(String id) {
    _todos.removeWhere((t) => t.id == id);

    notifyListeners();
  }
}