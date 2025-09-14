import 'package:velix/velix.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';
import 'main.types.g.dart'; // your generated registry file

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

void main() {
  // Initialize or register all descriptors

  registerAllDescriptors();

  // manual mapping

  var mapper = Mapper([
    mapping<Money, Money>()
    //.map(from: "currency", to: "currency"),
        .map(all: matchingProperties()),

    mapping<Product, Product>()
        .map(from: "status", to: "status")
        .map(from: "name", to: "name")
        .map(from: "price", to: "price", deep: true),

    mapping<Invoice, Invoice>()
        .map(from: "date", to: "date")
        .map(from: "products", to: "products", deep: true)
  ]);

  var input = Invoice(
      date: DateTime.now(),
      products: [
        Product(name: "p1", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p2", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p3", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p4", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p5", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p6", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p7", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p8", price: Money(currency: "EU", value: 1), status: Status.available),
        Product(name: "p9", price: Money(currency: "EU", value: 1), status: Status.available),
      ]
  );

  var result = mapper.map(input);

  // json

  JSON(
      validate: false,
      converters: [Convert<DateTime,String>((value) => value.toIso8601String(), convertTarget: (str) => DateTime.parse(str))],
      factories: [Enum2StringFactory()]);

  var json = JSON.serialize(input);
  result = JSON.deserialize<Invoice>(json);
}
