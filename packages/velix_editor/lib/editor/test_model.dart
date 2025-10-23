import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

@Dataclass()
class Address {
  // instance data

  @Attribute()
  String city = "";
  @Attribute()
  String street = "";

  // constructor

  Address({required this.city, required this.street});

  // methods

  @Inject()
  String hello(String message) {
    print(message);
    return "world";
  }
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

  // methods

  @Inject()
  String hello(String message) {
    print(message);
    return "hello $message";
  }
}

 List<User> allUsers = [
  User(
    name: "Andreas",
    age: 60,
    single: true,
    address: Address(
        city: "Cologne",
        street: "Neumarkt"
    ),
  ),
  User(
      name: "Nika",
      age: 60,
      single: true,
      address: Address(
          city: "Cologne",
          street: "Neumarkt"
      )
  )
];

@Injectable()
@Dataclass()
class TestPage {
  // instance data

  @Attribute()
  User? user;
  @Attribute()
  List<User> users;

  // constructor

  TestPage() : users = allUsers, user = allUsers[0];

  // methods

  @Method()
  void selectUser(User user) {
    print("user = ${user.name}");

    this.user = user;
  }

  @Method()
  List<User> getUsers() {
    return users;
  }

  @Method()
  void hello(String message) {
    print(message);
  }
}