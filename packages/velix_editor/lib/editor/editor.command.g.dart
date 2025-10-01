// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'editor.dart';

mixin EditorScreenStateCommands on CommandController<EditorScreen> {
  // override

  @override
  void initCommands() {
    addCommand(
      "open",
      _open,
      i18n: 'editor:commands.open',
      icon: Icons.folder_open,
    );
    addCommand("save", _save, i18n: 'editor:commands.save', icon: Icons.save);
    addCommand(
      "revert",
      _revert,
      i18n: 'editor:commands.revert',
      icon: Icons.restore,
    );
    addCommand("undo", _undo, i18n: 'editor:commands.undo', icon: Icons.undo);
    addCommand("play", _play, label: 'Play', icon: Icons.play_arrow);
  }

  // command declarations

  Future<void> _open();
  void _save();
  void _revert();
  void _undo();
  void _play();

  // command bodies

  @Method()
  Future<void> open() async {
    await execute("open", []);
  }

  @Method()
  void save() {
    execute("save", []);
  }

  @Method()
  void revert() {
    execute("revert", []);
  }

  @Method()
  void undo() {
    execute("undo", []);
  }

  @Method()
  void play() {
    execute("play", []);
  }
}
