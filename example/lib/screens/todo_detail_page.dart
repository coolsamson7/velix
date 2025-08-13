import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:velix/velix.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';

part "todo_detail_page.command.g.dart";

class TodoDetailPage extends StatefulWidget {
  final Todo todo;

  const TodoDetailPage({super.key, required this.todo});

  @override
  State<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends State<TodoDetailPage> with CommandController<TodoDetailPage>, _TodoDetailPageStateCommands {
  // instance data

  late FormMapper mapper;

  // commands

  @Command()
  @override
  void _save() {
    if (mapper.validate()) {
      Todo todo = mapper.commit();

      final todoProvider = Provider.of<TodoProvider>(context, listen: false);

      // it could be a different object in case of immutable classes!

      todoProvider.updateTodo(todo);

      // close screen

      Navigator.pop(context);
    }
  }

  @Command()
  @override
  void _cancel() {

  }

  // override

  @override
  void updateCommandState() {
    setCommandEnabled("save", mapper.isDirty.value);
    setCommandEnabled("cancel", mapper.isDirty.value);
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    var twoWay = false;

    mapper = FormMapper(instance: widget.todo, twoWay: twoWay);

    mapper.isDirty.addListener(() {
      setState(() {
        updateCommandState();
      });
    });

    updateCommandState();
  }

  @override
  void dispose() {
    super.dispose();

    mapper.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    Widget result = CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.todo.title,
          style: TextStyle(
            fontSize: 17,         // Recommended standard size for nav bar
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,),

      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: mapper.getKey(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mapper.bind(CupertinoTextFormFieldRow, path: "title", context: context, args: {
                "placeholder": 'Titel',
                "style": const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                "padding": const EdgeInsets.symmetric(vertical: 12, horizontal: 8),   // add vertical padding
              }),
              const SizedBox(height: 16),
              mapper.bind(CupertinoTextFormFieldRow, context: context,  path: "details.author", args: {
                "placeholder": 'Author',
                "style": const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                "padding": const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              }),
              const SizedBox(height: 16),
              mapper.bind(CupertinoTextFormFieldRow, context: context,  path: "details.priority", args: {
                "placeholder": 'Priority',
                "style": const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                "padding": const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Erledigt:', style: TextStyle(fontSize: 18)),
                  mapper.bind(CupertinoSwitch, context: context, path: "completed")
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CupertinoButton(
                    onPressed: isCommandEnabled("save") ?  save : null,
                    child: const Text('Speichern')
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton.filled(
                    child: const Text('Löschen'),
                    onPressed: () {
                      todoProvider.removeTodo(widget.todo.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // set value

    mapper.setValue(widget.todo);

    // done

    return result;
  }
}
