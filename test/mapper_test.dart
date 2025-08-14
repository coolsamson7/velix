import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';

import 'main.dart';
import 'main.type_registry.g.dart';


void main() {
  group('mapper', () {

    registerAllDescriptors();

    // TODO
    // TODO register weg!
    TypeDescriptor.register(TypeDescriptor<Map<String, dynamic>>(name: "json" , constructor: ()=>HashMap<String,dynamic>(), constructorParameters: [], fields: []));

    test('map json', () {
      var money = Money(currency: "EU", value: 1);
      var mutable = Mutable(
        id: "id",
        price: money
      );


      /*var mapper = Mapper([
        mapping<Money, Map<String, dynamic>>()
            .map(from: "currency", to: JSONAccessor(name: "currency", type: String, index: 0))
            .map(from: "value", to: JSONAccessor(name: "value", type: int, index: 0)),
      ]);

      var result = mapper.map<Money, Map<dynamic, dynamic>>(money);

      print(result);*/

      var jsonMapper = JSONMapper<Money>();

      var json = JSON.serialize(money);
      var m = JSON.deserialize<Money>(json);

      print(json);

      // as

      var mutableMapper = JSONMapper<Mutable>();

      var result1 = JSON.serialize(mutable);

      print(result1);


      var r3 = JSON.deserialize<Mutable>(result1);

      print(r3);
    });


    test('map json collections', () {
      var money = Money(currency: "EU", value: 1);
      var collections = Collections(prices: [money, money, money]);

      var collectionsMapper = JSONMapper<Collections>();

      // warm up

      JSON.deserialize<Collections>(JSON.serialize(collections));

      print("serialize");

      var loops = 100000;
      var stopwatch = Stopwatch()..start();

      for (int i = 0; i < loops; i++) {
        JSON.serialize(collections);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');


      print("deserialize");

      stopwatch = Stopwatch()..start();

      var json = JSON.serialize(collections);

      print(json);

      for (int i = 0; i < loops; i++) {
        JSON.deserialize<Collections>(json);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

    });

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
      print("immutable root");
      var mapper = Mapper([
        mapping<Immutable, Immutable>()
            .map(from: "id", to: "id")
            .map(from: path("price", "currency"), to:  path("price", "currency"))
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