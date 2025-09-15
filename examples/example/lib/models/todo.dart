// ignore_for_file: unnecessary_import, unused_local_variable
import 'package:velix/velix.dart';

@Dataclass()
class Details {
  // instance data

  @Attribute(type: "maxLength 7")
  final String author;
  @Attribute(type: "greaterThan 0")
  final int priority;
  @Attribute()
  final DateTime date;

  const Details({required this.author, required this.priority, required this.date});
}

@Dataclass()
class Todo {
  // instance data

  @Attribute(type: "maxLength 7")
  String id;
  @Attribute(type: "maxLength 10")
  String title;
  @Attribute()
  bool completed;
  @Attribute()
  Details? details;

  // constructor

  Todo({required this.id, required this.title, this.details, this.completed = false});
}

@Dataclass()
class TestData {
  // instance data

  @Attribute(type: "maxLength 7")
  String string_data;
  @Attribute(type: "greaterThan 0")
  int int_data;
  @Attribute(type: "greaterThan 0")
  int slider_int_data;
  @Attribute()
  bool bool_data;
  @Attribute()
  final DateTime datetime_data;

  // constructor

  TestData({required this.string_data, required this.int_data, required this.slider_int_data, required this.bool_data, required this.datetime_data});
}