
import '../metadata/widget_data.dart';

abstract class Event {
  final Object? source;

  Event({this.source});
}

class LoadEvent extends Event {
  WidgetData? widget;

  LoadEvent({required this.widget, required super.source});
}

class PropertyChangeEvent extends Event {
  WidgetData? widget;

  PropertyChangeEvent({required this.widget, required super.source});
}

class SelectionEvent extends Event {
  WidgetData? selection;

  SelectionEvent({required this.selection, required super.source});
}

class CreateWidgetEvent extends Event {
  WidgetData? widget;

  CreateWidgetEvent({required this.widget, required super.source});
}

enum MessageType {
  warning,
  error
}

enum MessageEventType {
  add,
  delete,
  replace,
  clear,
}

class Message {
  MessageType type;
  String message;
  Function? onClick;

  Message({required this.type, required this.message, this.onClick});
}

class MessageEvent extends Event{
  // instance data

  MessageEventType type;
  List<Message> messages;

  // constructor

  MessageEvent({required super.source, required this.type, this.messages = const []});
}

