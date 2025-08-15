import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';

import 'main.dart';
import 'main.type_registry.g.dart';


void main() {
  group('json', () {

    registerAllDescriptors();

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
          price: Money(currency: "EU", value: 1)
      );

      var json = JSON.serialize(input);
      var result = JSON.deserialize<Mutable>(json);

      final isEqual = TypeDescriptor.deepEquals(input, result);
      expect(isEqual, isTrue);
    });

    test('map json collections', () {
      var money = Money(currency: "EU", value: 1);
      var input = Collections(prices: [money]);

      var json = JSON.serialize(input);
      var result = JSON.deserialize<Collections>(json);

      final isEqual = TypeDescriptor.deepEquals(input, result);
      expect(isEqual, isTrue);
    });

    test('benchmark json collections', () {
      var money = Money(currency: "EU", value: 1);
      var collections = Collections(prices: [money, money, money]);

      // warm up

      var json = JSON.serialize(collections);

      JSON.deserialize<Collections>(json);

      // serialize

      print("serialize json");

      var loops = 100000;
      var stopwatch = Stopwatch()..start();

      for (int i = 0; i < loops; i++) {
        JSON.serialize(collections);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

      // deserialize

      print("deserialize json");

      stopwatch = Stopwatch()..start();

      for (int i = 0; i < loops; i++) {
        JSON.deserialize<Collections>(json);
      }

      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds} ms, avg=${stopwatch.elapsedMilliseconds / loops}');

    });
  });
}