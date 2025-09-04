import 'package:flutter/material.dart';
import 'package:sample/services/services.dart';
import 'package:velix/di/di.dart';
import '../models/todo.dart';

@Injectable()
class TodoProvider with ChangeNotifier {
  // instance data

  final TodoService todoService;
  final List<Todo> todos = [];
  //TODO List<Todo> get todos => _todos;

  // constructor

  TodoProvider({required this.todoService});

  // public

  Future<Todo> addTodo(String title) async {
    Todo todo = Todo(id: DateTime.now().toString(), details: Details(author: "Andreas", priority: 1, date: DateTime.now()), title: title);

    todos.add(todo);

    await Future.delayed(const Duration(milliseconds: 1000)); // just a test

    notifyListeners();

    return todo;
  }

  void updateTodo(Todo todo) {
    // we know the object is not immutable

    notifyListeners();
  }

  void toggleTodo(String id) {
    final todo = todos.firstWhere((t) => t.id == id);
    todo.completed = !todo.completed;

    notifyListeners();
  }

  void removeTodo(String id) {
    todos.removeWhere((t) => t.id == id);

    notifyListeners();
  }
}