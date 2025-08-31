
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/configuration/configuration.dart';
import 'package:velix/di/di.dart';
import 'package:velix/util/tracer.dart';
import 'package:velix/velix.dart';

import 'main.dart';
import 'main.type_registry.g.dart';

void main() {
  group('di', () {
    // register types

    //Velix.bootstrap;

    registerAllDescriptors();

    Tracer(
        isEnabled: true,
        trace: ConsoleTrace("%d [%l] %p: %m %f"), // d(ate), l(evel), p(ath), m(message)
        paths: {
          "": TraceLevel.full,
          "di": TraceLevel.full
        });

    test('features', () {
      var environment = Environment(forModule: TestModule, features: ["dev"]);

      environment.report();

      var conditional = environment.get<ConditionalBase>();

      expect(conditional.runtimeType, equals(ConditionalDev));

      environment = Environment(forModule: TestModule, features: ["prod"]);

      conditional = environment.get<ConditionalBase>();

      expect(conditional.runtimeType, equals(ConditionalProd));
    });

    test('injectable', () {
      var environment = Environment(forModule: TestModule);

      environment.report();

      var foo = environment.get<Foo>();

      expect(foo, isNotNull);
      expect(foo.bar, isNotNull);

      var otherFoo = environment.get<Foo>();

      expect(foo, equals(otherFoo));
    });

    test('factory', () {
      var environment = Environment(forModule: TestModule);

      environment.report();

      var baz = environment.get<Baz>();

      expect(baz, isNotNull);
    });

    test('inheritance', () {
      var environment = Environment(forModule: TestModule);

      environment.report();

      var result = environment.get<RootType>();

      expect(result is DerivedType, isTrue);
    });

    test('inherited environments', () {
      var environment = Environment(forModule: TestModule);

      environment.report();

      var foo = environment.get<Foo>();
      var bar =  environment.get<Bar>();

      expect(foo, isNotNull);

      // sub environment

      var childEnvironment = Environment(parent: environment);

      var bar1 = childEnvironment.get<Bar>();
      var foo1 = childEnvironment.get<Foo>();

      expect(bar, equals(bar1));
      expect(foo, isNot(foo1));
    });
  });
}