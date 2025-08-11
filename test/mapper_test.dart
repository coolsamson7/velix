import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';

import 'package:flutter_application/main.widget_registry.g.dart';
import 'package:flutter_application/models/todo.dart';


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

      var source = Mutable(id: '1', price: Money(currency: "EU", value: 1));

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

      var target = mapper.map(Money(currency: "EU", value: 1));

      // benchmark

      var loops = 100000;
      final stopwatch = Stopwatch()..start();

      // 👇 Code to benchmark
      for (int i = 0; i < loops; i++) {
        mapper.map(Money(currency: "EU", value: 1));
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');


      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
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

      var target = mapper.map(source);

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
      print("immutable root");
      var mapper = Mapper([
        mapping<Immutable, Immutable>()
            .map(from: "id", to: "id")
            .map(from: path("price", "currency"), to:  path("price", "currency"))
            .map(from: path("price", "value"), to: path("price", "value"))
      ]);

      var source = Immutable(id: '1', price: Money(currency: "EU", value: 1));

      var target = mapper.map(source);

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