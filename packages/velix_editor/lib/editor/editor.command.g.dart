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
    addCommand(
      "new",
      _newFile,
      i18n: 'editor:commands.new',
      icon: Icons.note_add,
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
  Future<void> _newFile();
  Future<void> _save();
  void _revert();
  void _undo();
  void _play();

  // command bodies

  @Method()
  Future<void> open() async {
    await execute("open", []);
  }

  @Method()
  Future<void> newFile() async {
    await execute("newFile", []);
  }

  @Method()
  Future<void> save() async {
    await execute("save", []);
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
