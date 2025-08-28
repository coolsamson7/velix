
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/di/di.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/util/tracer.dart';

import 'main.dart';
import 'main.type_registry.g.dart';

void main() {
  group('di', () {
    // register types

    registerAllDescriptors();

    Tracer(
        isEnabled: true,
        trace: ConsoleTrace("%d [%l] %p: %m"), // d(ate), l(evel), p(ath), m(message)
        paths: {
          "": TraceLevel.full,
          "di": TraceLevel.full
        });

    test('injectable', () {
      var environment = Environment(TestModule);

      environment.report();

      var foo = environment.get<Foo>(Foo);

      expect(foo, isNotNull);
      expect(foo.bar, isNotNull);

      var otherFoo = environment.get<Foo>(Foo);

      expect(foo, equals(otherFoo));
    });

    test('factory', () {
      var environment = Environment(TestModule);

      environment.report();

      var baz = environment.get<Baz>(Baz);

      expect(baz, isNotNull);
    });

    test('lifecycle', () {
      var environment = Environment(TestModule);

      environment.report();

      var baz = environment.get<Baz>(Baz);

      expect(baz, isNotNull);
    });
  });
}