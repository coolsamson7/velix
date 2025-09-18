
import '../metadata/widget_data.dart';

abstract class Event {
  final Object? source;

  Event({this.source});
}

class PropertyChangeEvent extends Event {
  WidgetData? widget;

  PropertyChangeEvent({required this.widget, required super.source});
}

class SelectionEvent extends Event {
  WidgetData? selection;

  SelectionEvent({required this.selection, required super.source});
}