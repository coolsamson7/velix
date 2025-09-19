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
    addCommand("open", _open, icon: Icons.folder_open);
    addCommand("save", _save, icon: Icons.save);
    addCommand("revert", _revert, icon: Icons.undo);
    addCommand("play", _play, icon: Icons.play_arrow);
  }

  // command declarations

  void _open();
  void _save();
  void _revert();
  void _play();

  // command bodies

  void open() {
    execute("open", []);
  }

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
