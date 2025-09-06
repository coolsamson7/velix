
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


Detailed infromation can be found in the corresponding [Wiki](https://github.com/coolsamson7/velix/wiki).

Lets get a quick overview on the topics

# Mapping

A general purpose mapping framework let's you declaratively specify mappings:
```dart
 var mapper = Mapper([
        mapping<Money, Money>()
            .map(all: matchingProperties()),

        mapping<Product, Product>()
            .map(from: "status", to: "status")
            .map(from: "name", to: "name")
            .map(from: "price", to: "price", deep: true),

        mapping<Invoice, Invoice>()
            .map(from: "date", to: "date")
            .map(from: "products", to: "products", deep: true)
      ]);

var invoice = Invoice(...);

var result = mapper.map(invoice);
```


As a special case, json mapping is supported as well:
```dart
// overall configuration  

JSON(
   validate: true,
   converters: [Convert<DateTime,String>((value) => value.toIso8601String(), convertTarget: (str) => DateTime.parse(str))],
   factories: [Enum2StringFactory()]
);

// funny money class

@Dataclass()
@JsonSerializable(includeNull: true) // doesn't make sense here, but anyway...
class Money {
  // instance data

  @Attribute(type: "length 7")
  @Json(name: "c", required: false, defaultValue: "EU")
  final String currency;
  @Json(name="v", required: false, defaultValue: 0)
  @Attribute()
  final int value;

  const Money({required this.currency, this.value});
}

var price = Money(currency: "EU", value: 0);

var json = JSON.serialize(price);
var result = JSON.deserialize<Money>(json);
```

# Installation

The library is published on [pub.dev](https://pub.dev/packages/velix_mapper )
