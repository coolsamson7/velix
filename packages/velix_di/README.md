
![License](https://img.shields.io/github/license/coolsamson7/velix)
![Dart](https://img.shields.io/badge/Dart-3.0-blue)
[![Docs](https://img.shields.io/badge/docs-online-blue?logo=github)](https://coolsamson7.github.io/velix/)
[![Flutter CI](https://github.com/coolsamson7/velix/actions/workflows/flutter.yaml/badge.svg)](https://github.com/coolsamson7/velix/actions/workflows/flutter.yaml)

<img width="320" height="320" alt="velix" src="https://github.com/user-attachments/assets/21141c08-9a34-4337-88af-173ad2f044a6" />

# Introduction

Velix is Dart/Flutter library implementing some of the core parts required in every Flutter application:
- type meta data
- specification and validation of type constraints
- general purpose mapping framework
- json mapper
- model-based two-way form data-binding
- i18n
- dependency injection container
- command pattern for ui actions

Check out some articles on Medium:

  - [General purpose mapper](https://medium.com/@andreas.ernst7/velix-introducing-a-powerful-and-expressive-general-purpose-mapping-and-validation-library-e27a56501604)
  - [Commands](https://medium.com/@andreas.ernst7/from-code-to-command-crafting-scalable-and-interceptable-commands-in-flutter-75ed90f136cb)
  - [Model driven Forms](https://medium.com/@andreas.ernst7/model-driven-forms-for-flutter-e0535659489a)

Detailed information can be found in the corresponding [Wiki](https://github.com/coolsamson7/velix/wiki).

# Dependency Injection

This package contains the dependency injection container, that takes care of the assembly and lifecycle of managed objects.
It utilizes the type code-generator of the core package.

**Example**:

```Dart
// a module defines the set of managed objects according to their library location
// it can import other modules!
@Module(imports: [])
class TestModule {
  @Create()
  ConfigurationManager createConfigurationManager() {
    return ConfigurationManager();
  }

  // factory method
  @Create()
  ConfigurationValues createConfigurationValues() {
    // will register with the configuration manager via a lifecycle method!
    return ConfigurationValues({
      "foo": 4711
    });
  }
}

// singleton is the default, btw.
@Injectable(scope: "singleton", eager: false)
class Bar {
  const Bar();
}

// environment means that it is a singleton per environment
@Injectable(scope: "environment")
class Foo {
  // instance data

  final Bar bar;
  
  // constructor injection

  const Foo({required this.bar});
}

@Injectable()
class Factory {
  const Factory();
  
  // some lifecycle callbacks

  // injection of the surrounding environment
  @OnInit()
  void onInit(Environment environment) {
    ...
  }

  @OnDestroy()
  void onDestroy() {
    ...
  }
  
  // config value injection!

  @Inject()
  void setFoo(Foo foo, @Value("foo", defaultValue: 1) int value) {
    ...
  }

  // another method based factory
  @Create() 
  Baz createBaz(Bar bar) {
    return Baz();
  }
}

var environment = Environment(forModule: TestModule);
var foo = environment.get<Foo>();

var inherited = Environment(parent: environment);
var inheritedFoo = environment.get<Foo>(); // will be another instance, since it has the scope "environment"
```

Features are:

- constructor and setter injection
- injection of configuration variables
- possibility to define custom injections
- post processors
- support for factory methods
- support for eager and lazy construction
- support for scopes "singleton", "request" and "environment"
- possibility to add custom scopes
- conditional registration of classes and factories ( aka profiles in spring )
- lifecycle events methods `@OnInit`, `@OnDestroy`, `@OnRunning`
- Automatic discovery and bundling of injectable objects based on their module location, including support for recursive imports
- Instantiation of one or possible more isolated container instances — called environments — each managing the lifecycle of a related set of objects,
- Support for hierarchical environments, enabling structured scoping and layered object management.

# Installation

The library is published on [pub.dev](https://pub.dev/packages/velix_di )
