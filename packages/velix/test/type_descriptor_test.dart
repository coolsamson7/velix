import 'package:flutter_test/flutter_test.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';

import 'type_descriptor_test.types.g.dart';

@Dataclass()
class Base {
  String id;

  Base({required this.id});
}

@Dataclass()
class Derived extends Base {
  int number;

  Derived({required this.number, required super.id});
}

@Dataclass()
class Lazy {
  Lazy? parent;

  Lazy({required this.parent});
}

void main() {
  registerTypes();

  group('types', () {
    test('inheritance', () {
      var base = TypeDescriptor.forType(Base);
      var derived = TypeDescriptor.forType(Derived);

      expect(derived.getFields().length, equals(2));
      expect(identical(derived.superClass, base) , equals(true));
    });

    test('lazy', () {
      var lazy = TypeDescriptor.forType(Lazy);

      //expect(lazy.lazy, equals(false));
      //expect(identical((lazy.getField("parent").type as ObjectType).typeDescriptor, lazy), equals(true));
    });
  });
}