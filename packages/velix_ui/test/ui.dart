import 'package:velix/reflectable/reflectable.dart';

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
class Money {
  // instance data

  @Attribute(type: "maxLength 7")
  final String currency;
  @Attribute(type: "greaterThan 0")
  final int value;

  const Money({required this.currency, required this.value});
}


@Dataclass()
class ImmutableProduct {
  final String name;
  final Money price;
  final Status status;

  ImmutableProduct({required this.name, required this.price, required this.status});
}

@Dataclass()
class ImmutableRoot {
  // instance data

  @Attribute()
  final ImmutableProduct product;

  const ImmutableRoot({required this.product});
}
