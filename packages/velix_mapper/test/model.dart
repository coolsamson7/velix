
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix/reflectable/reflectable.dart';


@Dataclass()
class Mutable {
  // instance data

  @Attribute(type: "maxLength 7")
  String id;
  @Attribute()
  Money price;
  @Attribute()
  DateTime? dateTime;

  // constructor

  Mutable({required this.id, required this.price, required this.dateTime});
}


@Dataclass()
class Collections {
  // instance data

  @Attribute()
  final List<Money> prices;

  const Collections({required this.prices});
}


@Dataclass()
enum Status {
  available
}

@Dataclass()
class Product {
  String name;
  Money price;
  Status status;

  Product({required this.name, required this.price, required this.status});
}

@Dataclass()
class Invoice {
  final DateTime date;
  final List<Product> products;

  Invoice({required this.products, required this.date});
}

@Dataclass()
@JsonSerializable(includeNull: true)
class Money {
  // instance data

  @Attribute(type: "maxLength 7")
  @Json(name: "currency", includeNull: true, required: true, defaultValue: "EU", ignore: false)
  final String currency;
  @Json(includeNull: true, required: true, defaultValue: 1, ignore: false)
  @Attribute(type: "greaterThan 0")
  final int value;

  const Money({required this.currency, required this.value});
}

@Dataclass()
class Base {
  final String name;

  Base(this.name);
}

@Dataclass()
class Derived extends Base {
  final int number;

  Derived(super.name, {required this.number});
}

@Dataclass()
class Types {
  final int int_var;
  final double double_var;
  final bool bool_var;
  final String string_var;

  Types({required this.int_var, required this.double_var, required this.bool_var, required this.string_var});
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