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