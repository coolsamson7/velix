import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';

import 'main.dart';
import 'main.type_registry.g.dart';

void main() {
  group('json', () {
    // register types

    registerAllDescriptors();

    JSON(
        validate: false,
        converters: [Convert<DateTime,String>((value) => value.toIso8601String(), convertTarget: (str) => DateTime.parse(str))],
        factories: [Enum2StringFactory()]);

    test('map immutable json', () {
      var input = Money(currency: "EU", value: 1);

      var json = JSON.serialize(input);
      var result = JSON.deserialize<Money>(json);

      final isEqual = TypeDescriptor.deepEquals(input, result);
      expect(isEqual, isTrue);
    });

    test('map mutable json', () {
      var input = Mutable(
          id: "id",
          price: Money(currency: "EU", value: 1),
          dateTime: DateTime.now()
      );

      var json = JSON.serialize(input);
      var result = JSON.deserialize<Mutable>(json);

      final isEqual = TypeDescriptor.deepEquals(input, result);
      expect(isEqual, isTrue);
    });

    test('map list', () {
      var money = Money(currency: "EU", value: 1);
      var input = Collections(prices: [money]);

      var json = JSON.serialize(input);
      var result = JSON.deserialize<Collections>(json);

      final isEqual = TypeDescriptor.deepEquals(input, result);
      expect(isEqual, isTrue);
    });

    test('validate object', () {
      JSON(validate: true);

      var input = Money(currency: "1234567890", value: 1);

      var json = JSON.serialize(input);

      expect(
            () => JSON.deserialize<Money>(json),
        throwsA(isA<ValidationException>()), // or use any matcher: throwsException, etc.
      );

      JSON(validate: false);
    });

    test('benchmark', () {
      //JSON(validate: false);

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

      // warm up

      var json = JSON.serialize(input);

      JSON.deserialize<Invoice>(json);

      // serialize

      var loops = 100000;
      var stopwatch = Stopwatch()..start();

      for (int i = 0; i < loops; i++) {
        JSON.serialize(input);
      }

      stopwatch.stop();
      print('Serialized $loops, time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

      // deserialize

      stopwatch = Stopwatch()..start();

      for (int i = 0; i < loops; i++) {
        JSON.deserialize<Invoice>(json);
      }

      stopwatch.stop();
      print('Deserialized $loops, time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');
    });
  });
}