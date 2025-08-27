
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/di/di.dart';
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

    test('di', () {
      var environment = Environment(TestModule);

      var foo = environment.get<Foo>(Foo);

      expect(foo, isNotNull);
      expect(foo.bar, isNotNull);

      var otherFoo = environment.get<Foo>(Foo);

      expect(foo, equals(otherFoo));
    });
  });
}