
![License](https://img.shields.io/github/license/coolsamson7/velix)
![Dart](https://img.shields.io/badge/Dart-3.0-blue)
[![Docs](https://img.shields.io/badge/docs-online-blue?logo=github)](https://coolsamson7.github.io/velix/)
[![Flutter CI](https://github.com/coolsamson7/velix/actions/workflows/flutter.yaml/badge.svg)](https://github.com/coolsamson7/velix/actions/workflows/flutter.yaml)
[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

# Velix UI Editor

This package implements a wysiwyg UI editor and runtime engine with JSON as the persistence format.

<img width="1487" height="877" alt="editor" src="https://github.com/user-attachments/assets/3b605ecd-6d1d-4b53-ad56-ced6f13e0243" />

# Goals and Design Principles

## Developer tool

The editor and the engine are ment to simplify the development process but not replace it.
So, it's not one of those no-code tools ( e.g. FlutterFlow ) but more a developer tool.

On the other hand it of course offers all the typical features of a wysiwyg editor:
- drag & drop
- widget tree
- dynamic palette
- property editors
- undo
- live preview
- i18n
- shortcuts

Currently, the approach is to be able to design individual pages only.

The most complex approach was to create an editor that would not only be used to design widget structures, only to generate 
static flutter code in the end. Instead, the runtime engine will be included in the target application and will dynamically 
render a widget tree based on a JSON structure.

Why complex? Well, because we need to tackle a bunch of problems 

- widgets are able to be bound to a property of a connected object ( e.g. "user.name" )
- events should trigger callbacks ( e.g. on button press call "login(user, password)"

Both problems are solved via reflection based on the velix meta-data infrastructure, which in turn relies on a code generator.

The corresponding chapters will add more details to the solution.

## Model Based

Every aspect is model based and pluggable avoiding any hardcoded logic. This relates to different aspects.
- the set of widget types
- the configuration data of every widget 
- the component that is responsible to render a widget
- the property editors that are rendered.

Let's look at the different aspects:

### Widget Data

A widget is defined by a set of configuration properties declared as a class.

**Example**

```Dart
@Dataclass()
@DeclareWidget(name: "button", group: "widgets", icon: "widget_button")
@JsonSerializable(discriminator: "button", includeNull: false)
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  Value label;
  @DeclareProperty(group: "font")
  Font? font;
  @DeclareProperty(group: "style")
  Color? foregroundColor;
  @DeclareProperty(group: "style")
  Color? backgroundColor;
  @DeclareProperty(group: "layout")
  Insets? padding;
  @DeclareProperty(group: "events", editor: CodeEditorBuilder, validator: ExpressionPropertyValidator)
  String? onClick;

  // constructor

  ButtonWidgetData({super.type = "button", super.cell, super.children, required this.label, this.font, this.foregroundColor, this.backgroundColor, this.padding, this.onClick});
}
```

Different annotations are used to register the widget type and its meta-data on startup.
This process relies on the basic `velix` di framework that relies of a custom code generator.

### Widget Renderer

Every widget type - in our case a `button` type - requires a renderer, that will consume the configuration properties.

**Example**

```Dart
@Injectable()
class ButtonEditWidgetBuilder extends WidgetBuilder<ButtonWidgetData> {
  // constructor

  ButtonEditWidgetBuilder() : super(name: "button", edit: true);

  // override

  @override
  Widget create(ButtonWidgetData data, Environment environment, BuildContext context) {
    // In edit mode, make the button non-interactive
    return IgnorePointer(
      ignoring: true,
      child: ElevatedButton(
        onPressed: () {  }, // This won't be called due to IgnorePointer

        style: ElevatedButton.styleFrom(
            foregroundColor: data.foregroundColor,
            backgroundColor: data.backgroundColor,
            textStyle: data.font?.textStyle(),
            padding: data.padding?.edgeInsets()
        ),
        child: Text(data.label.value),
      ),
    );
  }
}
```

In this case a widget is created that will be displayed in edit-mode, showing labels and handled if selected and the outline of the widget.
A separate builder is responsible for the runtime widget, which if course is more complex, since it will also deal with events.

Currently both the edit and runtime builders are part of the same package. It is an option to split the different artifacts, which 
would make sure that the runtime code is smaller and would also allow for separate dynamic and replaceable "themes". 

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

This class will register an editor for all properties of type `String`.

## JSON data format

Widgets are stored as a tree-structure in JSON that is a 1:1 mapping of the properties
and defined converters ( e.g. font weight ).

**Example**

```json
{
  "type": "dropdown",
  "placeholder": {
    "type": "value",
    "value": "Select..."
  },
  "databinding": "user",
  "onSelect": "selectUser(value)",
  "children": [
    {
      "type": "for",
      "context":  "getUsers()",
      "children": [
        {
          "type": "label",
          "label": {
            "type": "binding",
            "value": "name"
          },
          "children": []
        }
      ]
    }
  ]
}
```

This data will be stored as an asset in the real application, and will be an argument to the corresponding rendering widget.

## Databinding

Widgets can be bound to class properties by specifying a path ( e.g. "user.name" ). The engine will make sure to retrieve the values
 and to modify the respective instances accordingly. Depending on the configuration the underlying instance will be updated live or delayed on commit.
The mechanism utilizes the form binding implemented by the package `velix_ui`.

## Code Evaluation

Events need to call user code. ( e.g. button press ).
A complete dart expression language parser and compiler is implemented that will execute the corresponding code.

Both data binding and code expressions are validated against a loaded meta-model, which is a result of one of the generators.
The corresponding editors on top offer autocompletion possibilities as known from typical IDEs.

## Templates

Data-Binding to a single property is one thing, but if we think of a drop-down or a dynamic list, we would like to bind
complex objects - e.g. a list of users - to widget templates.

The solution is intuitive and simple. A specific widget called "for" can be inserted in a parent widget and will be bound
to a context which is either a path or an expression, e.g. "users" or as a method "getUsersByType(type)".
Inside the editor you will be allowed to insert child widgets that in turn can bind to a special variable "value" which will
represent an element of the context list.

So in case of a dropdown, we will insert the fpr-widget and in turn add a label widget bound to "value".

How cool ist that?

