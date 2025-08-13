import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:sample/models/todo.dart';
import '../screens/todo_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:velix/velix.dart';
import '../providers/todo_provider.dart';

part 'todo_home_page.command.g.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> with CommandController<TodoHomePage>, _TodoHomePageStateCommands {
  // instance data

  final TextEditingController _controller = TextEditingController();

  // commands

  @override
  @Command(i18n: "main.addTodo1",  icon: CupertinoIcons.add, lock: LockType.view) // icon: CupertinoIcons.add
  Future<Todo> _addTodo() async {
      var todo = await context.read<TodoProvider>().addTodo(_controller.text);

      _controller.clear();

      updateCommandState();

      return todo;
  }

  @override
  @Command(i18n: "main.removeTodo") // icon: CupertinoIcons.delete
  void _removeTodo(String id) {
    context.read<TodoProvider>().removeTodo(id);
  }

  @override
  @Command(i18n: "main.toggleTodo")
  void _toggleTodo(String id) {
    context.read<TodoProvider>().toggleTodo(id);
  }

  // internal

  @override
  void updateCommandState() {
    setCommandEnabled("addTodo",  _controller.text.isNotEmpty);

    // more...
  }

  // override

  @override
  void dispose() {
    _controller.removeListener(updateCommandState);
    _controller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(updateCommandState);

    updateCommandState();
  }

  @override
  Widget build(BuildContext context) {
    return CommandView(
      commands: getCommands(),
      child: Consumer<TodoProvider>(
        builder: (context, todoProvider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _controller,
                        placeholder: 'hello',
                      ),
                    ),
                    CommandButton(
                      command: getCommand('addTodo'),
                      icon: CupertinoIcons.add,
                      iconOnly: true
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: todoProvider.todos.length,
                  itemBuilder: (context, index) {
                    final todo = todoProvider.todos[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child:GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => TodoDetailPage(todo: todo),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey4)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  todo.title,
                                  style: TextStyle(
                                    decoration: todo.completed
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                              CupertinoSwitch(
                                value: todo.completed,
                                onChanged: (_) => toggleTodo(todo.id),
                              ),
                              CommandButton(
                                command: getCommand('removeTodo'),
                                icon: CupertinoIcons.delete,
                                iconOnly: true,
                                args: [todo.id],
                              ),
                            ],
                          ),
                        ),
                      )

                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
