// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// CommandGenerator
// **************************************************************************

part of 'todo_detail_page.dart';

mixin _TodoDetailPageStateCommands on CommandController<TodoDetailPage> {
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

  @Method()
  void save() {
    execute("save", []);
  }

  @Method()
  void cancel() {
    execute("cancel", []);
  }
}
