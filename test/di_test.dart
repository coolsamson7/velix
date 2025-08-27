
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/di/di.dart';

import 'main.dart';
import 'main.type_registry.g.dart';

void main() {
  group('di', () {
    // register types

    registerAllDescriptors();

    test('di', () {
      var environment = Environment(TestModule);

      var foo = environment.get<Foo>(Foo);

      expect(foo, isNotNull);
      expect(foo.bar, isNotNull);
    });
  });
}