
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'dart:async';

import '../main.dart';
import 'dart:convert';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

class JsonEditorPanel extends StatelessWidget {
  // constructor

  const JsonEditorPanel({super.key});

  // override

  @override
  Widget build(BuildContext context) {
    String jsonString = const JsonEncoder.withIndent('  ').convert({"foo": 1}); // TODO

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        child: HighlightView(
          jsonString,
          language: 'json',
          theme: githubTheme,
          padding: const EdgeInsets.all(8),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /*Map<String, dynamic> _serializeWidget(WidgetData widget) {
    Map<String, dynamic> map = {'type': widget.type};

    final meta = metadata[widget.type]!;

    for (var prop in meta.properties) {
      final value = TypeDescriptor.forType(widget.runtimeType).get(widget, prop.name);
      if (value is WidgetData) {
        map[prop.name] = _serializeWidget(value);
      } else if (value is List<WidgetData>) {
        map[prop.name] = value.map((w) => _serializeWidget(w)).toList();
      } else {
        map[prop.name] = value;
      }
    }

    return map;
  }*/
}


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
@Injectable(scope: "environment", eager: false)
class MessageBus {
  // instance data

  final _streamController = StreamController<_Message>.broadcast();

  // constructor

  MessageBus() {
    print("MessageBus");
  }

  // public

  /// Publish a message on a given topic.
  void publish(String topic, [dynamic data]) {
    print("[MessageBus] publish: topic=$topic, data=$data (${data.runtimeType})");

    _streamController.add(_Message(topic, data));
  }

  /// Subscribe to a topic.
  StreamSubscription<T> subscribe<T>(
      String topic,
      void Function(T) onData,
      ) {
    print("[MessageBus] subscribe: topic=$topic, type=$T");

    return _streamController.stream
        .where((msg) => msg.topic == topic && msg.data is T)
        .map((msg) => msg.data as T)
        .listen((event) {
      print("[MessageBus] deliver: topic=$topic, event=$event");
      onData(event);
    });
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

abstract class Event {
  final Object? source;

  Event({this.source});
}

class PropertyChangeEvent extends Event {
  WidgetData? widget;

  PropertyChangeEvent({required this.widget, required super.source});
}

class SelectionEvent extends Event {
  WidgetData? selection;

  SelectionEvent({required this.selection, required super.source});
}

class Property {
  // instance data

  final String name;
  final Type type;

  // constructor

  Property({required this.name, required this.type});

  // public

  dynamic createDefault() {// TODO _> metadata
    switch (type) {
      case String:
        return "";
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

  T get<T>(dynamic instance,  String property) {
    return type.get<T>(instance, property);
  }

  void set(dynamic instance,  String property, dynamic value) {
    type.set(instance, property, value);
  }

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

  late final Environment environment;
  late final Theme theme;
  bool selected = false;

  late final StreamSubscription selectionSubscription;
  late final StreamSubscription propertyChangeSubscription;

  // internal

  void select(SelectionEvent event) {
    if ( event.source != this) {
      if (event.selection != widget.model) {
        setState(() {
          selected = event.selection == widget.model;
        });
      }
    }
  }

  void changed(PropertyChangeEvent event) {
    if ( event.widget == widget.model) {
      setState(() {});
      print("change");
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    theme = environment.get<Theme>();

    selectionSubscription = environment.get<MessageBus>().subscribe<SelectionEvent>("selection", (event) => select(event));
    propertyChangeSubscription = environment.get<MessageBus>().subscribe<PropertyChangeEvent>("property-changed", (event) => changed(event));
  }

  @override
  void dispose() {
    super.dispose();

    selectionSubscription.cancel();
    propertyChangeSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final child = theme[widget.model.type].create(widget.model);

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
        onTap: () => environment.get<MessageBus>().publish("selection", SelectionEvent(selection: widget.model, source: this)),
        behavior: HitTestBehavior.translucent,
        child: Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                if (selected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ),
                if (selected)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(width: 8, height: 8, color: Colors.blue),
                  ),
              ],
            )
        ),
      );
  }
}

// panel

@Injectable()
abstract class PropertyEditorBuilder<T> {
  // lifecycle

  @Inject()
  void setup(PropertyEditorRegistry registry) {
    registry.register<T>(this);
  }

  // abstract

  Widget buildEditor({
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  });
}

@Injectable()
class StringEditorBuilder extends PropertyEditorBuilder<String> {
  // override

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

@Injectable()
class PropertyEditorRegistry {
  // instance data

  final Map<Type, PropertyEditorBuilder> _editors = {};

  void register<T>(PropertyEditorBuilder editor) {
    _editors[T] = editor;
  }

  // public

  PropertyEditorBuilder? resolve(Type type) => _editors[type];
}

class PropertyPanel extends StatefulWidget {
  // instance data

  // constructor

  const PropertyPanel({super.key});

  // override

  @override
  State<PropertyPanel> createState() => _PropertyPanelState();
}

class _PropertyPanelState extends State<PropertyPanel> {
  // instance data

  WidgetData? selected;
  late final MessageBus bus;
  late final PropertyEditorRegistry editorRegistry;
  StreamSubscription? subscription;
  late final TypeRegistry typeRegistry;

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();
    typeRegistry = EnvironmentProvider.of(context).get<TypeRegistry>();
    editorRegistry = EnvironmentProvider.of(context).get();

    // Listen for selection changes

    subscription ??= bus.subscribe<SelectionEvent>("selection", (event) {
      setState(() => selected = event.selection);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return const Center(child: Text("No selection"));
    }

    final meta = typeRegistry[selected!.type];

    return ListView(
      children: meta.properties.map((prop) {
        final editor = editorRegistry.resolve(prop.type);
        if (editor == null) {
          return ListTile(title: Text("${prop.name} (no editor)"));
        }

        final value = meta.get(selected!, prop.name);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: editor.buildEditor(
            label: prop.name,
            value: value,
            onChanged: (newVal) {
              meta.set(selected!, prop.name, newVal);

              // notify canvas/other panels

              bus.publish("property-changed", PropertyChangeEvent(widget: selected, source: this));
            },
          ),
        );
      }).toList(),
    );
  }
}

class EditorCanvas extends StatefulWidget {
  // instance data

  final List<WidgetData> models;
  final Map<String, MetaData> metadata;
  const EditorCanvas({super.key, required this.models, required this.metadata});

  // override

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  // instance data

  TypeRegistry? typeRegistry;

  // override

  @override
  Widget build(BuildContext context) {
    typeRegistry ??= EnvironmentProvider.of(context).get<TypeRegistry>();

    return DragTarget<Object>(
      onWillAccept: (_) => true,
      onAccept: (incoming) {
        // palette

        if (incoming is String) {

          WidgetData newWidget = typeRegistry![incoming].create();

          setState(() => widget.models.add(newWidget));
        }
        // reparenting
        else if (incoming is WidgetData) {
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

// the overall screen, that combines all aspects

class EditorScreen extends StatefulWidget {
  // instance data

  final List<WidgetData> models;
  final Map<String, MetaData> metadata;

  // constructor

  const EditorScreen({super.key, required this.models, required this.metadata});

  // override

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // instance data

  late final Environment environment;

  // constructor

  late final List<StreamSubscription> subscriptions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // create message bus

    environment = Environment(parent: EnvironmentProvider.of(context));

    // create bus

    environment.get<MessageBus>();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subscriptions)
      sub.cancel();

    environment.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentProvider(
        environment: environment,
        child: Row(
          children: [
            LeftPanelSwitcher(
              panels: {
                "tree": WidgetTreePanel(models: widget.models),
                "palette": WidgetPalette(typeRegistry: environment.get<TypeRegistry>()),
                "json": JsonEditorPanel(), // JSON view
              }),

            Expanded(
              flex: 2,
              child: EditorCanvas(models: widget.models, metadata: widget.metadata),
            ),
            Container(
              width: 300,
              color: Colors.white,
              child: PropertyPanel(),
            ),
          ],
        )
    );
  }
}

class WidgetPalette extends StatelessWidget {
  // instance data

  //final List<String> widgetTypes; // e.g., ["text", "container"]
  final TypeRegistry typeRegistry;

  // constructor

  const WidgetPalette({super.key, required this.typeRegistry});

  // override

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: Colors.grey.shade300,
      child: ListView(
        children: typeRegistry.metaData.values.map((type) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Draggable<String>(
              data: type.name,
              feedback: Material(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blueAccent,
                  child: Text(type.name, style: const TextStyle(color: Colors.white)),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Text(type.name),
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
  // instance data

  final WidgetData model;

  // constructor

  const WidgetTreeNode({super.key, required this.model});

  // override

  @override
  State<WidgetTreeNode> createState() => _WidgetTreeNodeState();
}

class _WidgetTreeNodeState extends State<WidgetTreeNode> {
  // instance data

  bool expanded = true;
  bool selected = false;
  late final MessageBus bus;
  late final StreamSubscription<SelectionEvent> subscription;

  // internal

  void select(SelectionEvent event) {
    if ( event.source != this) {
      if (event.selection != widget.model) {
        setState(() {
          selected = event.selection == widget.model;
        });
      }
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();

    subscription = bus.subscribe<SelectionEvent>("selection", (event) => select(event));
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren =
        widget.model is ContainerWidgetData && (widget.model as ContainerWidgetData).children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => bus.publish("selection", SelectionEvent(selection: widget.model, source: this)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: selected ? Colors.blue.shade100 : null,
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
                  .map((child) => WidgetTreeNode(model: child))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class WidgetTreePanel extends StatelessWidget {
  // instance data

  final List<WidgetData> models;

  // constructor

  const WidgetTreePanel({super.key, required this.models});

  // override

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey.shade100,
      child: ListView(
        children: models
            .map((model) => WidgetTreeNode(model: model))
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
                icon: const Icon(Icons.code),
                tooltip: "JSON",
                color: selectedPanel == "json" ? Colors.blue : null,
                onPressed: () => setState(() => selectedPanel = "json"),
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