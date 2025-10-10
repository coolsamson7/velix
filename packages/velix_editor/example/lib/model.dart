
import 'package:velix/reflectable/reflectable.dart';

@Dataclass()
class Address {
  // instance data

  @Attribute()
  String city = "";
  @Attribute()
  String street = "";

  // constructor

  Address({required this.city, required this.street});
}

@Dataclass()
class User {
  // instance data

  @Attribute()
  String name = "";
  @Attribute()
  int age;
  @Attribute()
  Address address;
  @Attribute()
  bool single;

  // constructor

  User({required this.name, required this.address, required this.age, required this.single});
}
