import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:velix/databinding/widgets.dart';

import 'package:velix/velix.dart';

import '../models/todo.dart';

part "test_page.command.g.dart";

class TestPage extends StatefulWidget {
  // instance data

  TestData data = TestData(string_data: '', int_data: 1, slider_int_data: 1, bool_data: false, datetime_data: DateTime.now());

  TestPage({super.key});

  @override
  State<TestPage> createState() => TestPageState();
}

class TestPageState extends State<TestPage> with CommandController<TestPage>, TestPageStateCommands {
  // instance data

  late FormMapper mapper;

  // commands

  @Command()
  @override
  void _save() {
    if (mapper.validate()) {
      // mapper.commit<Todo>();


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

    mapper = FormMapper(instance: widget.data, twoWay: false);

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
    Widget result = CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.data.title,
          style: TextStyle(
            fontSize: 17,         // Recommended standard size for nav bar
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,),

      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SmartForm(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: mapper.getKey(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                mapper.text(path: "title",
                  context: context,
                  placeholder: 'Titel',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),  // add vertical padding
                ),
                const SizedBox(height: 16),
                mapper.text(context: context,  path: "details.author",
                    placeholder: 'Author',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8)
                ),
                const SizedBox(height: 16),
                mapper.slider(context: context,  path: "details.priority",
                  min: 0,
                  max: 10,
                ),
                const SizedBox(height: 16),
                mapper.date(context: context,  path: "details.date"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Erledigt:', style: TextStyle(fontSize: 18)),
                    mapper.bind("switch", context: context, path: "completed")
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
            )
          //}
          //),
        ),
      ),
    );

    // set value

    mapper.setValue(widget.data);

    // done

    return result;
  }
}