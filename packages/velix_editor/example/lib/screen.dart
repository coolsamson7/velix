import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/type_registry.dart';
import 'package:velix_editor/metadata/widget_data.dart';
import 'package:velix_editor/widget_container.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_ui/commands/command.dart';
import 'package:velix_ui/databinding/form_mapper.dart';
import 'package:velix_ui/provider/environment_provider.dart';

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

  late final Environment environment;
  late FormMapper mapper;
  late WidgetData screen;

  late User user;
  late StreamSubscription subscription;

  Future<void>? _initFuture;

  // constructor

  ExampleScreenState() {
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

    _initFuture = _initialize();
  }

  // callbacks

  void onEvent(event) {
    print(mapper.isDirty);
  }

  // internal

  Future<void> _initialize() async {
    final jsonString = await rootBundle.loadString('assets/screens/screen.json');

    var json = jsonDecode(jsonString);

    screen = JSON.deserialize<WidgetData>(json);

    setState(() { });
  }

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
  void initState() {
    super.initState();

    _initFuture = _initialize();
  }

  @override
  void dispose() {
    super.dispose();

    subscription.cancel();
  }

  @override
  void updateCommandState() {
    setCommandEnabled("save", true);
    //setCommandEnabled("undo", commandStack.isDirty());
    //setCommandEnabled("revert", commandStack.isDirty());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    updateCommandState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        else return WidgetContainer(
          context: WidgetContext(instance: this, mapper: mapper),
          models: [screen],
          typeRegistry: Environment(parent: EnvironmentProvider.of(context)).get<TypeRegistry>(),
        );
      }
    );
  }
}