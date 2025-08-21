import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:velix/velix.dart';

import '../models/todo.dart';

part "test_page.command.g.dart";

class TestPage extends StatefulWidget {
  // instance data

  const TestPage({super.key});

  @override
  State<TestPage> createState() => TestPageState();
}

class TestPageState extends State<TestPage>
    with CommandController<TestPage>, TestPageStateCommands {
  // instance data

  late FormMapper mapper;
  TestData data = TestData(
    string_data: '',
    int_data: 1,
    slider_int_data: 1,
    bool_data: false,
    datetime_data: DateTime.now(),
  );

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
  void _cancel() {}

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

    mapper = FormMapper(instance: data, twoWay: true);

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
      navigationBar: CupertinoNavigationBar(middle: Text('Databinding')),
      child: SafeArea(
        child: Column(
          children: [
            CupertinoFormSection.insetGrouped(
              children: [
                mapper.text(
                  path: "string_data",
                  context: context,
                  placeholder: "Enter",
                  prefix: "String",
                ),

                mapper.text(
                  path: "int_data",
                  context: context,
                  placeholder: "Enter",
                  prefix: "Int",
                ),

                CupertinoFormRow(
                  prefix: Text('Slider'),
                  child: mapper.slider(
                    path: "slider_int_data",
                    context: context,
                    min: 0,
                    max: 10,
                  ),
                ),

                CupertinoFormRow(
                  prefix: Text('Bool'),
                  child: mapper.Switch(path: "bool_data", context: context),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: CupertinoTextField(
                controller: TextEditingController(
                  text: const JsonEncoder.withIndent(
                    '  ',
                  ).convert(JSON.serialize(data)),
                ),
                readOnly: true,
                maxLines: 8,
                minLines: 3,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: CupertinoColors.black,
                ),
                decoration: null,
              ),
            ),
          ],
        ),
      ),
    );

    // set value

    mapper.setValue(data);

    // done

    return result;
  }
}
