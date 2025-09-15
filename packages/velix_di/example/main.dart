import 'package:velix_di/velix_di.dart';

import 'main.types.g.dart';

@Module(includeSubdirectories: false)
class TestModule {
  @Create()
  ConfigurationManager createConfigurationManager() {
    return ConfigurationManager();
  }

  @Create()
  ConfigurationValues createConfigurationValues() {
    return ConfigurationValues({
      "foo": {
        "bar": "4711"
      }
    });
  }
}

@Injectable(scope: "singleton", eager: true)
class Bar {
  const Bar();
}

@Injectable(factory: false)
class Baz {
  const Baz();
}

@Injectable(scope: "environment")
class Foo {
  // instance data

  final Bar bar;

  const Foo({required this.bar});
}

@Injectable(scope: "singleton", eager: true)
class Factory {
  const Factory();

  @OnInit()
  void onInit(Environment environment) {
    print("onInit $environment");
  }

  @OnDestroy()
  void onDestroy() {
    print("onDestroy");
  }

  @Inject()
  void setFoo(Foo foo, @Value("foo.bar", defaultValue: 1) int value) {
    print(foo);
  }

  @Create()
  Baz createBaz(Bar bar) {
    return Baz();
  }

}

void main() {
  // bootstrap velix

  Velix.bootstrap;

  // register types

  registerAllDescriptors();

  var environment = Environment(forModule: TestModule);

  var bar = environment.get<Foo>();
  print(bar);
}