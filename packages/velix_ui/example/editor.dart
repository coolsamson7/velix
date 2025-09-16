
import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

class Property {
  final String name;
  final Type type;

  // constructor

  Property({required this.name, required this.type});
}

// we will use that for generic property panels
class MetaData {
  final String name;
  final Type type;
  List<Property> properties;

  MetaData({required this.name, required this.type, required this.properties});

  T parse<T>(Map<String,dynamic> data) {
    return JSON.deserialize<T>(data);
  }
}

class TypeRegistry {
  Map<String,MetaData> types = {};

  T parse<T>(Map<String,dynamic> data) {
    var type = data["type"]!;

    return types[type]!.parse<T>(data);
  }
}

var typeRegistry = TypeRegistry();

abstract class WidgetBuilder<T> {
   Widget create(T data);
}

@Dataclass()
abstract class WidgetData {
  String type;

  WidgetData({required this.type});
}

@Dataclass()
class TextWidgetData extends WidgetData {
  String label;

  TextWidgetData({required this.label, required super.type});
}

class TextWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // instance data

  // constructor

  // override

  @override
  Widget create(TextWidgetData data) {
    return TextField(
      decoration: InputDecoration(labelText: data.label),
    );
  }
}

@Dataclass()
class ContainerWidgetData extends WidgetData {
  List<WidgetData> children;

  ContainerWidgetData({
    required this.children,
    super.type = "container",
  });
}

class ContainerWidgetBuilder extends WidgetBuilder<ContainerWidgetData> {
  @override
  Widget create(ContainerWidgetData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.children
          .map((child) => DynamicWidget(
        model: child,
        meta: typeRegistry.types[child.type]!,
      ))
          .toList(),
    );
  }
}


class Theme {
  Map<String, WidgetBuilder> widgets = {};
}

Theme runtimeTheme = Theme();

class DynamicWidget extends StatefulWidget {
  final WidgetData model;
  final MetaData meta;

  const DynamicWidget({super.key, required this.model, required this.meta});

  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}


class _DynamicWidgetState extends State<DynamicWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = runtimeTheme; // from DI or global
    final child = theme.widgets[widget.model.type]!.create(widget.model);

    return GestureDetector(
      onTap: () {
        selectionController.select(widget.model);
      },
      child: ValueListenableBuilder(
        valueListenable: selectionController.selected,
        builder: (_, selected, __) {
          final selectedNow = selected == widget.model;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (selectedNow)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                ),
              if (selectedNow)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    color: Colors.blue,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}




// panel

abstract class PropertyEditor {
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  });
}

class StringEditor extends PropertyEditor {
  @override
  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? ""),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class EditorRegistry {
  final Map<Type, PropertyEditor> _editors = {};

  void register<T>(PropertyEditor editor) {
    _editors[T] = editor;
  }

  PropertyEditor? resolve(Type type) => _editors[type];
}

final editorRegistry = EditorRegistry()
  ..register<String>(StringEditor())
  //..register<double>(DoubleEditor())
  //..register<int>(ColorEditor()); // for ARGB color ints

class PropertyPanel extends StatelessWidget {
  final WidgetData model;
  final MetaData meta;
  final ValueChanged<WidgetData> onChanged;

  const PropertyPanel({
    super.key,
    required this.model,
    required this.meta,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: meta.properties.map((prop) {
        final editor = editorRegistry.resolve(prop.type);
        if (editor == null) {
          return ListTile(
            title: Text("${prop.name} (no editor)"),
          );
        }

        final value = (model as dynamic)
            .toJson()[prop.name]; // assuming your data is mappable

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: editor.buildEditor(
            label: prop.name,
            value: value,
            onChanged: (newVal) {
              (model as dynamic).toJson()[prop.name] = newVal;
              onChanged(model);
            },
          ),
        );
      }).toList(),
    );
  }
}

class SelectionController {
  final selected = ValueNotifier<WidgetData?>(null);

  void select(WidgetData? widget) {
    selected.value = widget;
  }
}

final selectionController = SelectionController();

class EditorCanvas extends StatelessWidget {
  final List<WidgetData> models;
  final Map<String, MetaData> metadata;

  const EditorCanvas({super.key, required this.models, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: ListView(
        children: models.map((m) {
          final meta = metadata[m.type]!;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: DynamicWidget(model: m, meta: meta),
          );
        }).toList(),
      ),
    );
  }
}

class SelectionPropertyPanel extends StatelessWidget {
  final Map<String, MetaData> metadata;
  const SelectionPropertyPanel({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WidgetData?>(
      valueListenable: selectionController.selected,
      builder: (context, selected, _) {
        if (selected == null) {
          return const Center(child: Text("No selection"));
        }
        final meta = metadata[selected.type]!;
        return PropertyPanel(
          model: selected,
          meta: meta,
          onChanged: (updated) {
            // Force UI rebuild if needed
          },
        );
      },
    );
  }
}

class EditorScreen extends StatelessWidget {
  final List<WidgetData> models;
  final Map<String, MetaData> metadata;

  const EditorScreen({super.key, required this.models, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: EditorCanvas(models: models, metadata: metadata),
        ),
        Container(
          width: 300,
          color: Colors.white,
          child: SelectionPropertyPanel(metadata: metadata),
        ),
      ],
    );
  }
}

//

void main() {
  var meta = MetaData(name: "text", type: TextWidgetData, properties: [
    Property(name: "label", type: String)
  ]);

  var types = TypeRegistry();

  types.types["text"] = meta;

  var theme = Theme();

  // currently we do this manually, but we will use the code generator soon enough

  theme.widgets["text"] = TextWidgetBuilder();

  var textData = {
    "type": "text",
    "label": "label"
  };

  var widgetData = types.parse<WidgetData>(textData);
}