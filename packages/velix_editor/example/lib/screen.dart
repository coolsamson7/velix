import 'dart:async';

import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/metadata/widget_data.dart';
import 'package:velix_editor/util/assets.dart';
import 'package:velix_editor/widget_container.dart';
import 'package:velix_ui/commands/command.dart';
import 'package:velix_ui/databinding/form_mapper.dart';

import 'model.dart';

part "screen.command.g.dart";

class ExampleScreen extends StatefulWidget {
  // constructor

  const ExampleScreen({super.key});

  // override

  @override
  State<ExampleScreen> createState() => ExampleScreenState();
}

@Dataclass()
class ExampleScreenState extends State<ExampleScreen> with CommandController<ExampleScreen>, ExampleScreenStateCommands {
  // instance data

  late FormMapper mapper;
  late WidgetData screen;

  late User user;
  late StreamSubscription subscription;

  // constructor

  ExampleScreenState() {
    screen = Assets.assets().folder("screens")!.item("screen")!.get<WidgetData>();
    user = User(
        name: "Andreas",
        address: Address(
            city: "NY",
            street: "1st Street"
        ),
        age: 60,
        single: false
    );
    mapper = FormMapper(instance: this, twoWay: true);

    subscription = mapper.addListener((event) => onEvent, emitOnDirty: true);
  }

  // callbacks

  void onEvent(event) {
    print(mapper.isDirty);
  }

  // internal

  bool isDirty() {
    return mapper.isDirty;
  }

  // commands

  @Command(i18n: "editor:commands.save", icon: Icons.save)
  @override
  void _save() {
    if (mapper.isValid) {
      print(user);
    }
  }

  // override

  @override
  void dispose() {
    super.dispose();

    subscription.cancel();
  }

  @override
  void updateCommandState() {
    setCommandEnabled("save", true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    updateCommandState();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetContainer(
          widget: screen,
          mapper: mapper,
          instance: this
        );
  }
}