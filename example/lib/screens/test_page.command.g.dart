// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'test_page.dart';

mixin TestPageStateCommands on CommandController<TestPage> {
  // override

  @override
  void initCommands() {
    addCommand("save", _save);
    addCommand("cancel", _cancel);
  }

  // command declarations

  void _save();
  void _cancel();

  // command bodies

  void save() {
    execute("save", []);
  }

  void cancel() {
    execute("cancel", []);
  }
}
