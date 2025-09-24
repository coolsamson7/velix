# Velix UI Editor

This package implements a wysiwyg UI editor and runtime engine with JSON as the persistence format.

# Goals and Design Principles

## Developer tool

The editor and the engine are ment to simplify the development process but not replace it.
So, it's not one of those no-code tools ( e.g. FlutterFlow ) but more a developer tool.

On the other hand it still offers all of the typical features of a wysiwyg editor:
- drag & drop
- widget tree
- dynamic palette
- property editors
- undo
- live preview
- i18n
- shortcuts

<img width="2278" height="1688" alt="image" src="https://github.com/user-attachments/assets/76a3cdfd-2816-4446-9047-8bbe4ada7da8" />


Currently the approach is to be able to design individual pages only.

## Model Based

Every aspect is model based and pluggable avoiding any hardcoded logic. This relates to different aspects.
- the set of widget types
- the configuration data of every widget 
- the component that is responsible to render a widget
- the property editors that are rendered.

Let's look at the different aspects:

### Widget Data Definition

A widget is defined by a set of configuration properties declared as a class.

**Example**

```Dart
@Dataclass()
@DeclareWidget(name: "button", i18n: "editor:widgets.button.title", group: "widgets", icon: Icons.text_fields)
@JsonSerializable(discriminator: "button")
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(groupI18N: "editor:groups.general", i18n: "editor:widgets.button.label")
  String label;
  @DeclareProperty(group: "Font Properties")
  Font? font;
  @DeclareProperty(group: "Layout Properties")
  Padding? padding;

  // constructor

  ButtonWidgetData({super.type = "button", super.children = const [], required this.label, this.font, this.padding});
}
```

Different annotations are used to register the widget type and its meta-data on startup.
This process relies on the basic `velix` code generator triggered by the `@Dataclass` annotation.

### Widget Renderer

Every widget type - in our case a `button` type - requires a renderer, that will consume the configuration properties.

**Example**

```Dart

@Injectable()
class ButtonWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonWidgetBuilder() : super(name: "button");

  // internal

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment) {
    return ElevatedButton(
      ...
    );
  }
}
```

The `@Injectable` annotation is used by the `velix` dependency injection framework and will make sure, that a singleton instance is
created on startup of the corresponding container, which will in turn register the builder in a widget registry.

### Property Editor

The same logic is applied for property editors, which are used in a generic property panel.

**Example**

```Dart
Injectable()
class StringEditorBuilder extends PropertyEditorBuilder<String> {
  // override

  @override
  Widget buildEditor({
    required MessageBus messageBus,
    required CommandStack commandStack,
    required FieldDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return _StringEditorStateful(
      label: label,
      value: value ?? "",
      onChanged: onChanged,
    );
  }
}
```

This class will register an editor for properties of type `String`.

## JSON data format

Widgets are stored as a tree-structure in JSON that is a 1:1 mapping of the properties
and defined converters ( e.g. font weight ).

**Example**

```json
{
  "type": "container",
  "children": [
    {
    "type": "text",
    "children": [],
    "label": "Hello World"
    },
    {
    "type": "button",
    "children": [],
    "label": "PRESS",
    "font": {
      "size": 12,
      "weight": 100,
      "style": "normal"
      },
    "padding": {
      "left": 1,
      "top": 1,
      "right": 1,
      "bottom": 1
      }
    },
    {
    "type": "text",
    "children": [],
    "label": "Second Text"
    }
  ]
}
```

## Generic approach avoiding code generation

The framework tries to avoid any additional - on top of the meta-data - code generators, as they
introduce additional build steps and dependencies which can be avoided.

The only problematic part are actions, that need to access the surrounding infrastructure ( e.g. a page method )
including passing parameters - literal or variable references - or simple parameter expressions.

The current approach is to utilize generated meta-data ( e.g. class structures ) in order 
to allow for smart input code editors, and to evaluate the resulting expressions based
on the concrete runtime data using the [expression](https://pub.dev/packages/expressions) library.

Work in progress :-).




