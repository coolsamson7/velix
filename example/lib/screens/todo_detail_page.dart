import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/services/services.dart';

import 'package:velix/velix.dart' hide EnvironmentProvider;

import '../main.dart';
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
  late TodoProvider todoProvider;

  Environment? environment;

  // commands

  @Command()
  @override
  void _save() {
    if (mapper.validate()) {
      Todo todo = mapper.commit<Todo>();

      // it could be a different object in case of immutable classes!

      todoProvider.updateTodo(todo);

      // close screen

      Navigator.pop(context);
    }
  }

  @Command()
  @override
  void _cancel() {
    Navigator.pop(context);
  }

  // override

  @override
  void updateCommandState() {
    setCommandEnabled("save", mapper.isDirty);
    setCommandEnabled("cancel", true);
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    todoProvider = Provider.of<TodoProvider>(context, listen: false);

    mapper = FormMapper(instance: widget.todo, twoWay: false);

    mapper.addListener((event) {
      setState(() {});
    }, emitOnDirty: true, emitOnChange: true);

    updateCommandState();
  }

  @override
  void dispose() {
    super.dispose();

    mapper.dispose();

    environment?.destroy();
  }

  @override
  Widget build(BuildContext context) {
    environment ??= Environment(parent: EnvironmentProvider.of(context));

    // test

    environment?.get<PerWidgetState>();

    // update command state

    updateCommandState();

    Widget result = CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,

        // leading

        leading: CupertinoButton(
          minSize: 0,
          padding: EdgeInsets.symmetric(horizontal: 16),
          color: Colors.transparent,
          disabledColor: CupertinoColors.white,
          onPressed: isCommandEnabled("save") ? save : null,
          child: Text('Save', style: TextStyle(
            fontSize: 17,
            color: isCommandEnabled("save")
                ? CupertinoColors.activeBlue
                : CupertinoColors.inactiveGray, // grey text when disabled
          )),
        ),

        // trailing

        trailing: CupertinoButton(
          minSize: 0,
          padding: EdgeInsets.symmetric(horizontal: 16),
          color: Colors.transparent,
          onPressed: isCommandEnabled("cancel") ? cancel : null,
          child: Text('Cancel', style: TextStyle(
            fontSize: 17,
            color: isCommandEnabled("cancel")
                ? CupertinoColors.activeBlue
                : CupertinoColors.inactiveGray, // grey text when disabled
          ),),
        ),

        middle: Text(widget.todo.title,
          style: TextStyle(
            fontSize: 17,         // Recommended standard size for nav bar
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,),

      ),
      child: SafeArea(
        child: SmartForm(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: mapper.getKey(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoFormSection.insetGrouped(
                children: [
                  // title

                  CupertinoFormRow(
                      prefix: Text("Title"),
                      child: mapper.text(path: "title",
                        context: context,
                        placeholder: 'Enter'
                      )),

                  // author

                  CupertinoFormRow(
                      prefix: Text("Author"),
                      child:  mapper.text(path: "details.author",
                        context: context,
                        placeholder: 'Enter',
                      )),

                  // priority

                  CupertinoFormRow(
                      prefix: Text("Priority"),
                      child:  mapper.slider(context: context,  path: "details.priority",
                        min: 0,
                        max: 10,
                      )),

                  // date

                  //CupertinoFormRow(
                  //    prefix: Text("Date"),
                  //    child:   mapper.date(context: context,  path: "details.date")),

                  // done

                  CupertinoFormRow(
                      prefix: Text("Completed"),
                      child:  mapper.bind("switch", context: context, path: "completed")),
                ],
              )
            ],
          )
        ),
      ),
    );

    // set value

    mapper.setValue(widget.todo);

    // done

    return result;
  }
}
