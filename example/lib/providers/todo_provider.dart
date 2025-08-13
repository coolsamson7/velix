import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TodoProvider with ChangeNotifier {
  final List<Todo> _todos = [];

  TodoProvider();

  List<Todo> get todos => _todos;

  void addTodo(String title) async {
    Todo todo = Todo(id: DateTime.now().toString(), details: Details(author: "", priority: 1), title: title);

    _todos.add(todo);

    notifyListeners(); 
  }

  void updateTodo(Todo todo) {
    // we know the object is not immutable

    notifyListeners();
  }

  void toggleTodo(String id) {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.completed = !todo.completed;

    notifyListeners();
  }

  void removeTodo(String id) {
    _todos.removeWhere((t) => t.id == id);

    notifyListeners();
  }
}