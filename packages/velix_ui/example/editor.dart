
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

  MetaData operator [](String other) {
    return types[type]!;
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

  TextWidgetData({required this.label, super.type = "text"});
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
    return DragTarget<Object>(
      onWillAccept: (incoming) => true,
      onAccept: (incoming) {
        if (incoming is String) {
          // palette drop
          WidgetData newWidget = incoming == "text"
              ? TextWidgetData(label: "New Text")
              : ContainerWidgetData(children: []);
          data.children.add(newWidget);
        } else if (incoming is WidgetData) {
          // reparenting drop
          // remove from old parent
          _removeFromParent(incoming);
          data.children.add(incoming);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              color: Colors.grey.shade100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.children
                .map((child) => DynamicWidget(
              model: child,
              meta: typeRegistry[child.type],
              parent: data,
            ))
                .toList(),
          ),
        );
      },
    );
  }

  void _removeFromParent(WidgetData widget) {
    void removeRecursive(ContainerWidgetData container) {
      container.children.remove(widget);
      for (var child in container.children) {
        if (child is ContainerWidgetData) removeRecursive(child);
      }
    }

    /*for (var top in canvasModels) {
      if (top == widget) {
        canvasModels.remove(top);
      } else if (top is ContainerWidgetData) {
        removeRecursive(top);
      }
      }*/
  }
}




class Theme {
  Map<String, WidgetBuilder> widgets = {};
}

Theme runtimeTheme = Theme();

class DynamicWidget extends StatefulWidget {
  final WidgetData model;
  final MetaData meta;
  final WidgetData? parent; // optional reference to parent container

  const DynamicWidget({super.key, required this.model, required this.meta, this.parent});

  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = runtimeTheme;
    final child = theme.widgets[widget.model.type]!.create(widget.model);

    return LongPressDraggable<WidgetData>(
      data: widget.model,
      feedback: Material(
        child: Opacity(
          opacity: 0.7,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blueAccent,
            child: child,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: child),
      child: GestureDetector(
        onTap: () => selectionController.select(widget.model),
        behavior: HitTestBehavior.translucent,
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
                    child: Container(width: 8, height: 8, color: Colors.blue),
                  ),
              ],
            );
          },
        ),
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
  ..register<String>(StringEditor());
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
class EditorCanvas extends StatefulWidget {
  final List<WidgetData> models;
  final Map<String, MetaData> metadata;
  const EditorCanvas({super.key, required this.models, required this.metadata});

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAccept: (_) => true,
      onAccept: (incoming) {
        if (incoming is String) {
          // palette
          WidgetData newWidget = incoming == "text"
              ? TextWidgetData(label: "New Text")
              : ContainerWidgetData(children: []);
          setState(() => widget.models.add(newWidget));
        } else if (incoming is WidgetData) {
          // reparenting
          _removeFromParent(incoming);
          setState(() => widget.models.add(incoming));
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: Colors.grey.shade200,
          child: ListView(
            children: widget.models
                .map((m) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: DynamicWidget(model: m, meta: widget.metadata[m.type]!),
            ))
                .toList(),
          ),
        );
      },
    );
  }

  void _removeFromParent(WidgetData widget) {
    void removeRecursive(ContainerWidgetData container) {
      container.children.remove(widget);
      for (var child in container.children) {
        if (child is ContainerWidgetData) removeRecursive(child);
      }
    }

    /*for (var top in widget.models) {
      if (top == widget) {
        widget.models.remove(top);
      } else if (top is ContainerWidgetData) {
        removeRecursive(top);
      }
    }*/
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
        WidgetTreePanel(models: models, metadata: metadata),
        WidgetPalette(widgetTypes: metadata.keys.toList()), // palette
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


class WidgetPalette extends StatelessWidget {
  final List<String> widgetTypes; // e.g., ["text", "container"]

  const WidgetPalette({super.key, required this.widgetTypes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: Colors.grey.shade300,
      child: ListView(
        children: widgetTypes.map((type) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Draggable<String>(
              data: type,
              feedback: Material(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blueAccent,
                  child: Text(type, style: const TextStyle(color: Colors.white)),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Text(type),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// tree

class WidgetTreeNode extends StatefulWidget {
  final WidgetData model;
  final Map<String, MetaData> metadata;

  const WidgetTreeNode({super.key, required this.model, required this.metadata});

  @override
  State<WidgetTreeNode> createState() => _WidgetTreeNodeState();
}

class _WidgetTreeNodeState extends State<WidgetTreeNode> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectionController.selected.value == widget.model;
    final hasChildren =
        widget.model is ContainerWidgetData && (widget.model as ContainerWidgetData).children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => selectionController.select(widget.model),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: isSelected ? Colors.blue.shade100 : null,
            child: Row(
              children: [
                if (hasChildren)
                  GestureDetector(
                    onTap: () {
                      setState(() => expanded = !expanded);
                    },
                    child: Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                Text(widget.model.type),
              ],
            ),
          ),
        ),
        if (hasChildren && expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (widget.model as ContainerWidgetData)
                  .children
                  .map((child) => WidgetTreeNode(model: child, metadata: widget.metadata))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class WidgetTreePanel extends StatelessWidget {
  final List<WidgetData> models;
  final Map<String, MetaData> metadata;

  const WidgetTreePanel({super.key, required this.models, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey.shade100,
      child: ListView(
        children: models
            .map((model) => WidgetTreeNode(model: model, metadata: metadata))
            .toList(),
      ),
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