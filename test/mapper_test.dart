import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';

import 'main.dart';
import 'main.type_registry.g.dart';


void main() {
  group('mapper', () {
    registerAllDescriptors();

    test('map collections', () {
      print("collections");

      var mapper = Mapper([
        mapping<Collections,Collections>()
            .map(from: "prices", to: "prices", deep: true),

        mapping<Money, Money>()
            .map(all: matchingProperties())
      ]);

      var source = Collections(prices: [Money(currency: "EU", value: 1)]);

      var target = mapper.map(source);

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark
      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

      print(target);

      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });

    test('map mutable root', () {
      print("mutable root");
      var mapper = Mapper([
        mapping<Mutable,Mutable>()
            .map(from: "id", to: "id")
            .map(from: path("price", "currency"), to: path("price", "currency"))
            .map(from: path("price", "value"), to: path("price", "value"))
            .finalize((s, t) => t.id = s.id)
      ]);

      var source = Mutable(id: '1', price: Money(currency: "EU", value: 1), dateTime: DateTime.now());

      Mutable target = mapper.map(source);

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark
      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

      print(target);

      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });

    test('map constant', () {
      print("constant");

      var mapper = Mapper([
        mapping<Money, Money>()
            .map(constant: "\$", to: "currency")
            .map(constant: 2, to: "value")
      ]);

      mapper.map(Money(currency: "EU", value: 1));

      // benchmark

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark

      for (int i = 0; i < loops; i++) {
        mapper.map(Money(currency: "EU", value: 1));
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');
    });

    test('map deep', () {
      print("deep");

      var mapper = Mapper([
        mapping<Immutable, Immutable>()
            .map(from: "id", to: "id", convert: Convert<String,String>((v) => "${v}XXX"))
            .map(from: "price", to: "price", deep: true),

        mapping<Money, Money>()
            .map(all: matchingProperties().except(["dunno"]))
      ]);

      var source = Immutable(id: '1', price: Money(currency: "EU", value: 1));

      mapper.map(source);

      // benchmark

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark

      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');


      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });

    test('map immutable root', () {
      var mapper = Mapper([
        mapping<Money, Money>()
            .map(all: matchingProperties()),

        mapping<Product, Product>()
            .map(from: "name", to: "name")
            .map(from: "price", to: "price", deep: true),

        mapping<Invoice, Invoice>()
            .map(from: "date", to: "date")
            .map(from: "products", to: "products", deep: true)
      ]);

      var input = Invoice(
          date: DateTime.now(),
          products: [
            Product(name: "p1", price: Money(currency: "EU", value: 1)),
            Product(name: "p2", price: Money(currency: "EU", value: 1)),
            Product(name: "p3", price: Money(currency: "EU", value: 1)),
            Product(name: "p4", price: Money(currency: "EU", value: 1)),
            Product(name: "p5", price: Money(currency: "EU", value: 1)),
            Product(name: "p6", price: Money(currency: "EU", value: 1)),
            Product(name: "p7", price: Money(currency: "EU", value: 1)),
            Product(name: "p8", price: Money(currency: "EU", value: 1)),
            Product(name: "p9", price: Money(currency: "EU", value: 1)),
          ]
      );

      var result = mapper.map(input);

      // benchmark

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark
      for (int i = 0; i < loops; i++) {
        mapper.map(input);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');


      print(result);
    });

    test('map immutable root', () {
      print("immutable root");
      var mapper = Mapper([
        mapping<Immutable, Immutable>()
            .map(from: "id", to: "id")
            .map(from: path("price", "currency"), to: path("price", "currency"))
            .map(from: path("price", "value"), to: path("price", "value"))
      ]);

      var source = Immutable(id: '1', price: Money(currency: "EU", value: 1));

      mapper.map(source);

      // benchmark

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark
      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });
  });
}