import 'package:velix/velix.dart';

@Dataclass()
class Details {
  // instance data

  @Attribute(type: "maxLength 7")
  final String author;
  @Attribute(type: "greaterThan 0")
  final int priority;

  const Details({required this.author, required this.priority});
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
class Collections {
  // instance data

  @Attribute()
  final List<Money> prices;

  const Collections({required this.prices});
}

@Dataclass()
class Money {
  // instance data

  @Attribute(type: "maxLength 7")
  final String currency;
  @Attribute(type: "greaterThan 0")
  final int value;

  const Money({required this.currency, required this.value});
}

@Dataclass()
class Mutable {
  // instance data

  @Attribute(type: "maxLength 7")
  String id;
  @Attribute()
  Money price;

  // constructor

  Mutable({required this.id, required this.price});
}

@Dataclass()
class Flat {
  // instance data

  @Attribute(type: "maxLength 7")
  final String id;
  @Attribute()
  final String price_currency;
  @Attribute()
  final int price_value;

  // constructor

  Flat({required this.id, required this.price_currency, required this.price_value});
}

@Dataclass()
class Immutable {
  // instance data

  @Attribute(type: "maxLength 7")
  final String id;
  @Attribute()
  final Money price;

  // constructor

  Immutable({required this.id, required this.price});
}