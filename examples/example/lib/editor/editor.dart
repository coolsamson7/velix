
import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'dart:async';

import '../main.dart';

//@Module(imports: [])
class EditorModule {
  @OnInit()
  void onInit() {
    print("EditorModule.onInit()");
  }

  @OnDestroy()
  void onDestroy() {
    print("EditorModule.onDestroy()");
  }
}

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Widget separator;

  const Breadcrumb({
    super.key,
    required this.items,
    this.separator = const Icon(Icons.chevron_right, size: 16),
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      children.add(
        InkWell(
          onTap: item.onTap,
          child: Text(
            item.label,
            style: TextStyle(
              color: item.onTap != null ? Colors.blue : Colors.grey[700],
              decoration:
              item.onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      );

      if (i < items.length - 1) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: separator,
        ));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  BreadcrumbItem({required this.label, this.onTap});
}

/// A simple message bus for pub/sub style communication.
class MessageBus {
  final _streamController = StreamController<_Message>.broadcast();

  /// Publish a message on a given topic.
  void publish(String topic, [dynamic data]) {
    _streamController.add(_Message(topic, data));
  }

  /// Subscribe to a topic.
  StreamSubscription<T> subscribe<T>(
      String topic,
      void Function(T data) handler,
      ) {
    return _streamController.stream
        .where((msg) => msg.topic == topic)
        .map((msg) => msg.data as T)
        .listen(handler);
  }

  /// Dispose the bus.
  void dispose() {
    _streamController.close();
  }
}

class _Message {
  final String topic;
  final dynamic data;
  _Message(this.topic, this.data);
}

class Property {
  // instance data

  final String name;
  final Type type;

  // constructor

  Property({required this.name, required this.type});

  // public

  dynamic createDefault() {
    switch (type) {
      case int:
        return 0;
      case double:
        return 0.0;
      case bool:
        return false;
    }

    if ( type is List)
      return [];

    throw Exception("unsupported type");
  }
}

// we will use that for generic property panels
class MetaData {
  // instance data

  final String name;
  final TypeDescriptor type;
  List<Property> properties;

  // constructor

  MetaData({required this.name, required this.type, required this.properties});

  // public

  WidgetData create() {
    Map<String,dynamic> args = {};

    // fetch defaults

    for ( var property in properties)
      args[property.name] = property.createDefault();

    // done

    return type.fromMapConstructor!(args);
  }

  T parse<T>(Map<String,dynamic> data) {
    return JSON.deserialize<T>(data);
  }
}

@Injectable()
class TypeRegistry {
  // static data

  static List<TypeDescriptor> types = [];

  // static methods

  static void declare(TypeDescriptor type) {
    types.add(type);
  }

  // instance data

  Map<String,MetaData> metaData = {};

  // constructor

  // lifecycle

  @OnInit()
  void setup() {
    for (var widgetType in types) {
      var declareWidget = widgetType.getAnnotation<DeclareWidget>()!;

      List<Property> properties = [];

      for ( var field in widgetType.getFields()) {
        var property = field.findAnnotation<DeclareProperty>();

        if (property != null) {
          properties.add(Property(name: field.name, type: field.type.type));
        }
      }

      var widgetMetaData = MetaData(name: declareWidget.name, type: widgetType, properties: properties);

      register(widgetMetaData);
    }
  }

  // public

  T parse<T>(Map<String,dynamic> data) {
    var type = data["type"]!;

    return metaData[type]!.parse<T>(data);
  }

  TypeRegistry register(MetaData metaData) {
    this.metaData[metaData.name] = metaData;

    return this;
  }

  MetaData operator [](String type) {
    return metaData[type]!;
  }
}

//var typeRegistry = TypeRegistry();

@Injectable(factory: false, eager: false) // TODO
abstract class WidgetBuilder<T extends WidgetData> {
  // instance data

  String name;

  // constructor

  WidgetBuilder({required this.name});

  // lifecycle

  @Inject()
  void setThema(Theme theme) {
    theme.register(this, name);
  }
  // abstract

  Widget create(T data);
}

// annotation

class DeclareWidget extends ClassAnnotation {
  // instance data

  final String name;

  // constructor

  const DeclareWidget({required this.name});

  // override

  @override
  void apply(TypeDescriptor type) {
    TypeRegistry.declare(type);
  }
}

class DeclareProperty extends FieldAnnotation {
  // instance data

  final String group;

  // constructor

  const DeclareProperty({required this.group});

  // override

  @override
  void apply(TypeDescriptor type, FieldDescriptor field) {
  }
}


@Dataclass()
abstract class WidgetData {
  String type;

  WidgetData({required this.type});
}

@Dataclass()
@DeclareWidget(name: "text")
class TextWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  String label;

  // constructor

  TextWidgetData({required this.label, super.type = "text"});
}

@Injectable()
class TextWidgetBuilder extends WidgetBuilder<TextWidgetData> {
  // instance data

  // constructor

  TextWidgetBuilder() : super(name: "text");

  // override

  @override
  Widget create(TextWidgetData data) {
    return TextField(
      decoration: InputDecoration(labelText: data.label),
    );
  }
}

@Dataclass()
@DeclareWidget(name: "container")
class ContainerWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  List<WidgetData> children;

  // constructor

  ContainerWidgetData({
    required this.children,
    super.type = "container",
  });
}

@Injectable()
class ContainerWidgetBuilder extends WidgetBuilder<ContainerWidgetData> {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  ContainerWidgetBuilder({required this.typeRegistry}) : super(name: "container");

  // lifecycle

  // override

  @override
  Widget create(ContainerWidgetData data) {
    return DragTarget<Object>(
      onWillAccept: (incoming) => true,
      onAccept: (incoming) {
        // palette
        if (incoming is String) {
          var metaData = typeRegistry[incoming];

          data.children.add(metaData.create());
        }
        // reparent
        else if (incoming is WidgetData) {
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



@Injectable()
class Theme {
  // instance data

  Map<String, WidgetBuilder> widgets = {};

  // constructor

  // public

  void register(WidgetBuilder builder, String name) {
    widgets[name] = builder;
  }

  WidgetBuilder operator [](String type) {
    return widgets[type]!;
  }
}

//Theme runtimeTheme = Theme();

class DynamicWidget extends StatefulWidget {
  // instance data

  final WidgetData model;
  final MetaData meta;
  final WidgetData? parent; // optional reference to parent container

  const DynamicWidget({super.key, required this.model, required this.meta, this.parent});

  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {
  // instance data

  Environment? environment;
  Theme? theme;

  // override

  @override
  Widget build(BuildContext context) {
    environment ??= Environment(parent: EnvironmentProvider.of(context));
    theme ??= environment!.get<Theme>();

    final child = theme![widget.model.type].create(widget.model);

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

        final value = TypeDescriptor.forType(model.runtimeType).get(model, prop.name);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: editor.buildEditor(
            label: prop.name,
            value: value,
            onChanged: (newVal) {
              TypeDescriptor.forType(model.runtimeType).set(model, prop.name, newVal);
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
        //WidgetTreePanel(models: models, metadata: metadata),
        //WidgetPalette(widgetTypes: metadata.keys.toList()), // palette
        LeftPanelSwitcher(
          panels: {
            "tree": WidgetTreePanel(models: models, metadata: metadata),
            "palette": WidgetPalette(widgetTypes: metadata.keys.toList()),
            //"images": ImagePanel(imageUrls: [
            //  "https://via.placeholder.com/100",
            //  "https://picsum.photos/100",
            //  "https://placekitten.com/100/100"
            //]
            }
            ),

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

class LeftPanelSwitcher extends StatefulWidget {
  final Map<String, Widget> panels; // panel name -> widget
  const LeftPanelSwitcher({super.key, required this.panels});

  @override
  State<LeftPanelSwitcher> createState() => _LeftPanelSwitcherState();
}

class _LeftPanelSwitcherState extends State<LeftPanelSwitcher> {
  String selectedPanel = "tree";

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Vertical Icon Bar
        Container(
          width: 40,
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.account_tree),
                tooltip: "Tree",
                color: selectedPanel == "tree" ? Colors.blue : null,
                onPressed: () => setState(() => selectedPanel = "tree"),
              ),
              IconButton(
                icon: const Icon(Icons.widgets),
                tooltip: "Palette",
                color: selectedPanel == "palette" ? Colors.blue : null,
                onPressed: () => setState(() => selectedPanel = "palette"),
              ),
              IconButton(
                icon: const Icon(Icons.image),
                tooltip: "Images",
                color: selectedPanel == "images" ? Colors.blue : null,
                onPressed: () => setState(() => selectedPanel = "images"),
              ),
            ],
          ),
        ),

        // Left Panel
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(selectedPanel),
            width: 200,
            color: Colors.grey.shade100,
            child: widget.panels[selectedPanel]!,
          ),
        ),
      ],
    );
  }
}