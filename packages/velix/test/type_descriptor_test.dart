import 'package:flutter_test/flutter_test.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';

import 'type_descriptor_test.types.g.dart';

@Dataclass()
class Base {
  @Attribute(type: "length 10")
  String id;

  Base({required this.id});
}

@Dataclass()
class Derived extends Base {
  @Attribute(type: "> 0")
  int number;

  Derived({required this.number, required super.id});
}

@Dataclass()
class Lists {
  String name;
  @Attribute(type: "min 1")
  List<Base> items = [];

  @Method()
  List<Base> getItems() {
    return items;
  }

  Lists({required this.name, required this.items});
}

@Dataclass()
class Lazy {
  Lazy? parent;

  Lazy({required this.parent});

  //@Inject()
  Derived set(Derived derived) {
    return derived;
  }
}

void main() {
  registerTypes();

  group('types', () {
    test('types', () {
      var base = TypeDescriptor.forType<Base>();

      expect(base.getField("id").type is StringType, equals(true));
      expect((base.getField("id").type as StringType).tests.length > 1, equals(true));
    });

    test('inheritance', () {
      var base = TypeDescriptor.forType<Base>();
      var derived = TypeDescriptor.forType<Derived>();

      expect(derived.getFields().length, equals(2));
      expect(identical(derived.superClass, base) , equals(true));
    });

    test('lazy', () {
      var lazy = TypeDescriptor.forType<Lazy>();

      print(lazy);

      //TODO expect(identical((lazy.getField("parent").type as ObjectType).typeDescriptor, lazy), equals(true));
    });
  });
}