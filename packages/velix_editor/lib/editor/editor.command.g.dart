// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'editor.dart';

mixin _EditorScreenStateCommands on CommandController<EditorScreen> {
  // override

  @override
  void initCommands() {
    addCommand("save", _save);
    addCommand("revert", _revert);
    addCommand("play", _play);
  }

  // command declarations

  void _save();
  void _revert();
  void _play();

  // command bodies

  void save() {
    execute("save", []);
  }

  void revert() {
    execute("revert", []);
  }

  void play() {
    execute("play", []);
  }
}
