
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
 
# Model-base form data-binding

## Motivation

Looking at the effort required in Flutter to handle even simple forms i was shocked and started looking for 
alternatives that gave my about the same level of verbosity or productivity as i have known for example in Angular.

While there are some form related libraries, they all skip the problem of binding widgets to values automatically, so i started my own
library reusing ideas, that i have known for at least 20 years :-)
Starting with the form binding quickly other solutions where integrated as well, that simplify development. 

## Solution idea

The idea is a model based declarative approach, that utilizes
- reflection information with respect to the bound classes and fields
- including type constraints on field level
- in combination with technical adapters that handle specific widgets and do the internal dirty work.

As a result, all the typical boilerplate code is completely gone, resulting in a fraction of necessary code.

**Example**

Let's look at a simple form example first.

Both the reflection and validation information is covered by specific decorators:

```dart
@Dataclass()
class Address {
  // instance data

  @Attribute(type: "length 100")
  final String city;
  @Attribute(type: "length 100")
  final String street;
  
  // constructor

  Address({required this.city, required this.street});
}

@Dataclass()
class Person {
  // instance data

  @Attribute(type: "length 100")
  String firstName;
  @Attribute(type: "length 100")
  String lastName;
  @Attribute(type: ">= 0")
  int age;
  @Attribute()
  Address address;
}
```

Inside the state of the form page, we can bind values easily


```dart
class PersonFormPageState extends State<PersonFormPage> {
  // instance data

  late FormMapper mapper;
  
  // override

  @override
  void initState() {
    super.initState();

    mapper = FormMapper(instance: widget.person, twoWay: true);

    mapper.isDirty.addListener(() {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    mapper.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Widget result = SmartForm(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: mapper.getKey(),
      ...
      mapper.text(path: "firstName", context: context, placeholder: 'First Name'), 
      mapper.text(path: "lastName", context: context, placeholder: 'Last Name'),
      mapper.text(path: "age", context: context, placeholder: 'Age'),
      mapper.text(path: "address.city", context: context, placeholder: 'City'),
      mapper.text(path: "address.street", context: context, placeholder: 'Street'),
    );

    // set value

    mapper.setValue(widget.person);

    // done

    return result;
  }
} 
```

You can already see some highlights:
- automatic handling of type validation ( e.g. length constraints ) and generation of error messages
- automatic coercion of types ( e.g. "age" is bound to a text field )
- handling of paths ( "address.city" ) including the necessary reconstruction of immutable classes ( with final fields )
- two-way data-binding, if requested

Two-way databinding will modify the underlying model immediately after every change in a associated widget.
If disabled, you would have to explicitly call `form.getValue()` to retrieve the updated model. The additional benefit you
would gain here is that the form mapper remembers the initial values and will change its `dirty` state accordingly, which means that 
a reverted change will bring the form back to a non-dirty state!


## Benefits
Velix drastically reduces the manual wiring and repetitive boilerplate that normally comes with Flutter forms.
With it, you get:

- No manual controllers – Forget TextEditingController, FocusNode, and onChanged spaghetti for every single field.

- Type-aware validation out of the box – Your @Attribute metadata drives validation rules automatically, without repeating them in the UI layer.

- Immutable model support – Handles reconstruction of immutable (final) classes automatically when updating nested fields.

- Two-way binding – Keep your widgets and model in sync without extra glue code; or opt for one-way binding with explicit getValue() retrieval.

- Path-based binding – Easily bind deeply nested fields (address.city) without manually drilling down in your widget code.

- Automatic dirty-state tracking – Know instantly if a form has unsaved changes and when it has been reverted to its original state.

- Minimal code footprint – Complex forms can be expressed in a fraction of the lines you’d normally need.

## Comparison to Existing Flutter Solutions

While Flutter has some established form libraries like
flutter_form_builder and reactive_forms, they still expect you to:

- Define FormControl or TextEditingController instances manually

- Wire each widget to its controller or form control

- Duplicate validation rules across model and UI layers

- Write boilerplate for converting between text and typed fields

Velix takes a different route:

- Model-driven – The form is generated from your annotated model, not from widget-level configuration.

- Automatic widget adapters – You don’t manually connect a controller; you just tell Velix which property to bind.

- Unified validation & transformation – Rules live once, in the model, and apply everywhere.

- Nested object awareness – Works with object graphs, not just flat maps of fields.

The result is a WPF/Angular-style binding experience in Flutter — something currently missing from the ecosystem.

# Installation

The library is published on [pub.dev](https://pub.dev/packages/velix_ui )
