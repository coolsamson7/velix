import 'package:velix/velix.dart';

@Module(imports:[])
class TestModule {
}

@Injectable(scope: "singleton", eager: true)
class Bar {
  const Bar();
}

@Injectable(factory: false)
class Baz {
  const Baz();
}

@Injectable(scope: "environment")
class Foo {
  // instance data

  final Bar bar;

  const Foo({required this.bar});
}

@Injectable(scope: "singleton", eager: true)
class Factory {
  const Factory();

  @OnInit()
  void onInit(Environment environment) {
    print("onInit $environment");
  }

  @OnDestroy()
  void onDestroy() {
    print("onDestroy");
  }

  @Inject()
  void setFoo(@Value(key: "foo") Foo foo) {
    print(foo);
  }

  @Create()
  Baz createBaz(Bar bar) {
    return Baz();
  }

}

@Dataclass()
class Collections {
  // instance data

  @Attribute()
  final List<Money> prices;

  const Collections({required this.prices});
}

@Dataclass()
class ImmutableRoot {
  // instance data

  @Attribute()
  final ImmutableProduct product;

  const ImmutableRoot({required this.product});
}

@Dataclass()
class MutableRoot {
  // instance data

  @Attribute()
  final Product product;

  const MutableRoot({required this.product});
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
@JsonSerializable(includeNull: true)
class Mutable {
  // instance data

  @Attribute(type: "maxLength 7")
  String id;
  @Attribute()
  Money price;
  @Attribute()
  @Json(name: "date-time")
  DateTime? dateTime;

  // constructor

  Mutable({required this.id, required this.price, required this.dateTime});
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

@Injectable(factory: false)
abstract class RootType {
  RootType();
}

@Injectable()
class DerivedType extends RootType {
  DerivedType();
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
enum Status {
  available
}

@Dataclass()
class ImmutableProduct {
  final String name;
  final Money price;
  final Status status;

  ImmutableProduct({required this.name, required this.price, required this.status});
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