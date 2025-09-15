
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

The core - which is the capturing of type meta-data -  is part of this package.
The other packages are:

- [dependency injection](https://github.com/coolsamson7/velix/tree/main/packages/velix_di)
- [mapping](https://github.com/coolsamson7/velix/tree/main/packages/velix_mapping)
- [i18n](https://github.com/coolsamson7/velix/tree/main/packages/velix_i18n)
- [form binding and commands ](https://github.com/coolsamson7/velix/tree/main/packages/velix_ui)

# Overview

## Validation

As in some popular Typescript libraries like `yup`, it is possible to declare type constraints with a simple fluent language

```dart
var type = IntType().greaterThan(0).lessThan(100);

type.validate(-1); // meeeh....will throw
```

## Type Meta-Data

In combination with a custom code generator, classes decorated with specific annotations - here `@Dataclass`-  emit the meta data:

```dart
@Dataclass()
class Money {
  // instance data

  @Attribute(type: "length 7")
  final String currency;
  @Attribute(type: ">= 0")
  final int value;

  const Money({required this.currency, required this.value});
}
```

The information will be used by a number of mechanisms, such as
- dependency injection container
- the mapping framework
- form data-binding.

# Installation

All packages are published to [pub.dev](pub.dev).

# Documentation

Detailed information can be found in the corresponding [Wiki](https://github.com/coolsamson7/velix/wiki).