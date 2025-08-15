import 'package:velix/velix.dart';

@Dataclass()
class Collections {
  // instance data

  @Attribute()
  final List<Money> prices;

  const Collections({required this.prices});
}

@Dataclass()
@JsonSerializable(includeNull: true)
class Money {
  // instance data

  @Attribute(type: "maxLength 7")
  @Json(name: "currency", includeNull: true, required: true, defaultValue: "EU", ignore: false)
  final String currency;
  @Json(name: "currency", includeNull: true, required: true, defaultValue: 1, ignore: false)
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
  final String priceCurrency;
  @Attribute()
  final int priceValue;

  // constructor

  Flat({required this.id, required this.priceCurrency, required this.priceValue});
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