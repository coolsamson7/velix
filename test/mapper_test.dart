import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';

import 'main.dart';
import 'main.type_registry.g.dart';


void main() {
  group('mapper', () {
    Velix.bootstrap;

    registerAllDescriptors();

    test('map conversion', () {
      var mapper = Mapper([
        mapping<Types,Types>()
            .map(from: "int_var", to: "double_var")
            .map(from: "bool_var", to: "bool_var")
            .map(from: "double_var", to: "int_var")
            .map(from: "string_var", to: "string_var")
      ]);

      var input = Types(int_var: 1, double_var: 2.0, string_var: "3", bool_var: true);

      Types result = mapper.map(input);
      
      expect(result.int_var, equals(2));
      expect(result.double_var, equals(1.0));
      expect(result.bool_var, equals(true));
      expect(result.string_var, equals("3"));
    });

    test('map inheritance', () {
      var baseMapping = mapping<Base,Base>()
          .map(from: "name", to: "name");

      var derivedMapping = mapping<Derived,Derived>()
          .derives(baseMapping)
          .map(from: "number", to: "number");

      var mapper = Mapper([
        derivedMapping
      ]);

      var input = Derived("derived", number: 1);

      Derived result = mapper.map(input);

      expect(result.name, equals("derived"));
      expect(result.number, equals(1));
    });

    test('map collections', () {
      var mapper = Mapper([
        mapping<Collections,Collections>()
            .map(from: "prices", to: "prices", deep: true),

        mapping<Money, Money>()
            .map(all: matchingProperties())
      ]);

      var source = Collections(prices: [Money(currency: "EU", value: 1)]);

       mapper.map(source);

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });

    test('map mutable root', () {
      var mapper = Mapper([
        mapping<Mutable,Mutable>()
            .map(from: "id", to: "id")
            .map(from: "dateTime", to: "dateTime")
            .map(from: path("price", "currency"), to: path("price", "currency"))
            .map(from: path("price", "value"), to: path("price", "value"))
            .finalize((s, t) => t.id = s.id)
      ]);

      var source = Mutable(id: '1', price: Money(currency: "EU", value: 1), dateTime: DateTime.now());

      mapper.map(source);

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

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

      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');


      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });

    test('benchmark', () {
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

      mapper.map(input);

      // benchmark

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark
      for (int i = 0; i < loops; i++) {
        mapper.map(input);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');
    });

    test('map immutable root', () {
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

      for (int i = 0; i < loops; i++) {
        mapper.map(source);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });
  });
}