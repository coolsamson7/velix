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
    addCommand("save", _save, label: 'Save', icon: CupertinoIcons.check_mark);
    addCommand(
      "revert",
      _revert,
      label: 'Revert',
      icon: CupertinoIcons.arrow_uturn_left,
    );
  }

  // command declarations

  void _save();
  void _revert();

  // command bodies

  void save() {
    execute("save", []);
  }

  void revert() {
    execute("revert", []);
  }
}
