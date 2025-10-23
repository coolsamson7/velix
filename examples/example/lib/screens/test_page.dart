import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:velix_ui/velix_ui.dart';
import 'package:velix/velix.dart';
import 'package:velix_mapper/velix_mapper.dart';

import '../models/todo.dart';

part "test_page.command.g.dart";

class TestPage extends StatefulWidget {
  // instance data

  TestData data;

  // constructor

  TestPage({super.key}) : data=TestData(
      string_data: '',
      int_data: 1,
      slider_int_data: 1,
      bool_data: false,
      datetime_data: DateTime.now(),
    );

  @override
  State<TestPage> createState() => TestPageState();
}

class TestPageState extends State<TestPage>
    with CommandController<TestPage>, TestPageStateCommands {
  // instance data

  late FormMapper mapper;

  String json = "";

  // constructor

  TestPageState();

  // internal

  void toJSON() {
    json = "";
    if (mapper.instance != null)
      json = JsonEncoder.withIndent(
        '  ',
      ).convert(JSON.serialize(mapper.instance));
  }

  Widget buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            //color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
            onPressed: getCommand("revert").enabled ? _revert : null,
            child: Row(
              children: const [
                Icon(CupertinoIcons.arrow_uturn_left, size: 18),
                SizedBox(width: 4),
                Text("Revert"),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            //color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(8),
            onPressed: getCommand("save").enabled ? _save : null,
            child: Row(
              children: const [
                Icon(CupertinoIcons.check_mark, size: 18),
                SizedBox(width: 4),
                Text("Save"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // commands

  @Command(label: "Save",  icon: CupertinoIcons.check_mark)
  @override
  void _save() {
    if (mapper.validate()) {
      widget.data = mapper.commit();
    }
  }

  @Command(label: "Revert", icon: CupertinoIcons.arrow_uturn_left)
  @override
  void _revert() {
    mapper.rollback();
  }

  // override

  @override
  void updateCommandState() {
    setCommandEnabled("save", mapper.isDirty && mapper.isValid);
    setCommandEnabled("revert", mapper.isDirty);
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    mapper = FormMapper(
      instance: TestData(
        string_data: '',
        int_data: 1,
        slider_int_data: 1,
        bool_data: false,
        datetime_data: DateTime.now(),
      ),
      twoWay: true,
    );

    mapper.addListener(
      (event) {
        updateCommandState();

        setState(() {});
      },
      emitOnChange: true,
      emitOnDirty: true,
    );

    updateCommandState();
  }

  @override
  void dispose() {
    super.dispose();

    mapper.dispose();
  }

  @override
  Widget build(BuildContext context) {
    updateCommandState();

    toJSON();

    Widget result = CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Databinding')),
      child: SafeArea(
        child: CommandView(
          commands: getCommands(),
          //toolbarCommands: [getCommand("save"), getCommand("revert")],
          child: SmartForm(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: mapper.getKey(),
            child: Column(
              children: [
                buildToolbar(),
                CupertinoFormSection.insetGrouped(
                  children: [
                    CupertinoFormRow(
                      prefix: Text("String"),
                      child: mapper.text(
                        path: "string_data",
                        context: context,
                        placeholder: "Enter",
                        //prefix: "String",
                      ),
                    ),

                    CupertinoFormRow(
                      prefix: Text("Int"),
                      child: mapper.text(
                        path: "int_data",
                        context: context,
                        placeholder: "Enter",
                        //prefix: "Int",
                      ),
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
                      prefix: Text('Date'),
                      child: mapper.date(
                        path: "datetime_data",
                        context: context,
                        //min: 0,
                        //max: 10,
                      ),
                    ),

                    CupertinoFormRow(
                      prefix: Text('Bool'),
                      child: mapper.Switch(path: "bool_data", context: context),
                    ),
                  ],
                ),
                CupertinoFormSection.insetGrouped(
                  children: [
                    CupertinoFormRow(
                      prefix: Text("Touched"),
                      child: Text(mapper.isTouched ? "Yes" : "No"),
                    ),

                    CupertinoFormRow(
                      prefix: Text("Dirty"),
                      child: Text(mapper.isDirty ? "Yes" : "No"),
                    ),

                    CupertinoFormRow(
                      prefix: Text("Valid"),
                      child: Text(mapper.validate() ? "Yes" : "No"),
                    ),

                    CupertinoFormRow(
                      //prefix: Align(
                      //  alignment: Alignment.topLeft,
                      //  child: Text("Data"),
                      //),

                      child: CupertinoTextField(
                        controller: TextEditingController(text: json),
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
              ],
            ),
          ),
        ),
      ),
    );

    // set value

    mapper.setValue(widget.data);

    // done

    return result;
  }
}
