// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'screen.dart';

mixin ExampleScreenStateCommands on CommandController<ExampleScreen> {
  // override

  @override
  void initCommands() {
    addCommand("save", _save, i18n: 'editor:commands.save', icon: Icons.save);
  }

  // command declarations

  void _save();

  // command bodies

  @Method()
  void save() {
    execute("save", []);
  }
}
