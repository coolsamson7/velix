import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'dart:async';

import '../main.dart';
import 'dart:convert';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

/// Reusable panel header with a title and close button
class PanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const PanelHeader({super.key, required this.title, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade400, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (onClose != null)
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}

/// Example wrapper that uses the header above a panel body
class PanelContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;

  const PanelContainer({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PanelHeader(title: title, onClose: onClose),
        Expanded(child: child),
      ],
    );
  }
}

class JsonEditorPanel extends StatelessWidget {
  // constructor

  const JsonEditorPanel({super.key});

  // override

  @override
  Widget build(BuildContext context) {
    String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert({"foo": 1}); // TODO

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade50,
      child: PanelContainer(
          title: "JSON",
          child: SingleChildScrollView(
            child: HighlightView(
              jsonString,
              language: 'json',
              theme: githubTheme,
              padding: const EdgeInsets.all(8),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          )),
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
              decoration: item.onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      );

      if (i < items.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: separator,
          ),
        );
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
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
    print(
      "[MessageBus] publish: topic=$topic, data=$data (${data.runtimeType})",
    );

    _streamController.add(_Message(topic, data));
  }

  /// Subscribe to a topic.
  StreamSubscription<T> subscribe<T>(String topic, void Function(T) onData) {
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
  final FieldDescriptor field;
  final String group;

  Type get type => field.type.type;

  // constructor

  Property({required this.name, required this.field, required this.group});

  // public

  dynamic createDefault() {
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

    return field.factoryConstructor!();
  }
}

// we will use that for generic property panels
class MetaData {
  // instance data

  final String name;
  final String group;
  final TypeDescriptor type;
  List<Property> properties;

  // constructor

  MetaData({required this.name, required this.group, required this.type, required this.properties});

  // public

  T get<T>(dynamic instance, String property) {
    return type.get<T>(instance, property);
  }

  void set(dynamic instance, String property, dynamic value) {
    type.set(instance, property, value);
  }

  WidgetData create() {
    Map<String, dynamic> args = {};

    // fetch defaults

    for (var property in properties)
      args[property.name] = property.createDefault();

    // done

    return type.fromMapConstructor!(args);
  }

  T parse<T>(Map<String, dynamic> data) {
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

  Map<String, MetaData> metaData = {};

  // constructor

  // lifecycle

  @OnInit()
  void setup() {
    for (var widgetType in types) {
      var declareWidget = widgetType.getAnnotation<DeclareWidget>()!;

      List<Property> properties = [];

      for (var field in widgetType.getFields()) {
        var property = field.findAnnotation<DeclareProperty>();

        if (property != null) {
          properties.add(Property(name: field.name, group: property.group, field: field));
        }
      }

      var widgetMetaData = MetaData(
        name: declareWidget.name,
        group: declareWidget.group,
        type: widgetType,
        properties: properties,
      );

      register(widgetMetaData);
    }
  }

  // public

  T parse<T>(Map<String, dynamic> data) {
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
  final String group;

  // constructor

  const DeclareWidget({required this.name, required this.group});

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
  void apply(TypeDescriptor type, FieldDescriptor field) {}
}

@Dataclass()
abstract class WidgetData {
  String type;

  WidgetData({required this.type});
}

@Dataclass()
@DeclareWidget(name: "text", group: "Widgets")
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
    return TextField(decoration: InputDecoration(labelText: data.label));
  }
}

@Dataclass()
@DeclareWidget(name: "container", group: "Container")
class ContainerWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "general")
  List<WidgetData> children;

  // constructor

  ContainerWidgetData({required this.children, super.type = "container"});
}

@Injectable()
class ContainerWidgetBuilder extends WidgetBuilder<ContainerWidgetData> {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  ContainerWidgetBuilder({required this.typeRegistry})
    : super(name: "container");

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
            color: Colors.grey.shade100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.children
                .map(
                  (child) => DynamicWidget(
                    model: child,
                    meta: typeRegistry[child.type],
                    parent: data,
                  ),
                )
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

/// Extracted draggable border wrapper
class DraggableWidgetBorder extends StatelessWidget {
  final Widget child;
  final bool selected;
  final String name;
  final WidgetData data;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;

  const DraggableWidgetBorder({
    super.key,
    required this.child,
    required this.name,
    required this.data,
    required this.selected,
    this.onDelete,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<WidgetData>(
      data: data,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: _buildBorderedChild(),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildBorderedChild()),
      child: GestureDetector(
        onTap: onSelect,
        // always pass a widget, not null
        child: _buildBorderedChild(),
      ),
    );
  }

  Widget _buildBorderedChild() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: selected
              ? BoxDecoration(
            border: Border.all(
              color: Colors.blue.withOpacity(0.5),
              width: 2,
            ),
          )
              : null,
          child: child,
        ),
        if (selected) ..._buildHandlesAndLabels(),
      ],
    );
  }

  List<Widget> _buildHandlesAndLabels() {
    return [
      // Top handle
      Positioned(
        top: -4,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: _buildHandle(),
        ),
      ),
      // Bottom handle
      Positioned(
        bottom: -4,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _buildHandle(),
        ),
      ),
      // Left handle
      Positioned(
        top: 0,
        bottom: 0,
        left: -4,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _buildHandle(),
        ),
      ),
      // Right handle
      Positioned(
        top: 0,
        bottom: 0,
        right: -4,
        child: Align(
          alignment: Alignment.centerRight,
          child: _buildHandle(),
        ),
      ),
      // Top-left name
      Positioned(
        top: -18,
        left: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: Colors.black.withOpacity(0.3),
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
      // Top-right delete
      if (onDelete != null)
        Positioned(
          top: -18,
          right: 0,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              color: Colors.black.withOpacity(0.3),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
    ];
  }


  Widget _buildHandle() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.5),
        shape: BoxShape.rectangle, // circle looks nicer
      ),
    );
  }
}


class DynamicWidget extends StatefulWidget {
  // instance data

  final WidgetData model;
  final MetaData meta;
  final WidgetData? parent; // optional reference to parent container

  const DynamicWidget({
    super.key,
    required this.model,
    required this.meta,
    this.parent,
  });

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
    if (event.source != this) {
      var newSelected = identical(event.selection, widget.model);
      if (newSelected != selected) {
        setState(() {
          selected = newSelected;
        });
      }
    }
  }

  void changed(PropertyChangeEvent event) {
    if (event.widget == widget.model) {
      setState(() {});
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    environment = EnvironmentProvider.of(context);
    theme = environment.get<Theme>();

    selectionSubscription = environment
        .get<MessageBus>()
        .subscribe<SelectionEvent>("selection", (event) => select(event));
    propertyChangeSubscription = environment
        .get<MessageBus>()
        .subscribe<PropertyChangeEvent>(
          "property-changed",
          (event) => changed(event),
        );
  }

  @override
  void dispose() {
    super.dispose();

    selectionSubscription.cancel();
    propertyChangeSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    print("create ${widget.model.type}, selected: $selected");

    return DraggableWidgetBorder(
      child: theme[widget.model.type].create(widget.model),
      name: widget.model.type,
      selected: selected,
      onDelete: () => {}, // TODO
      onSelect: () => environment.get<MessageBus>().publish(
        "selection",
        SelectionEvent(selection: widget.model, source: this),
      ),
      data: widget.model
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
  const PropertyPanel({super.key});

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
  final Map<String, bool> _expandedGroups = {};

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();
    typeRegistry = EnvironmentProvider.of(context).get<TypeRegistry>();
    editorRegistry = EnvironmentProvider.of(context).get<PropertyEditorRegistry>();

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

    // Group properties by group
    final groupedProps = <String, List<Property>>{};
    for (var prop in meta.properties) {
      groupedProps.putIfAbsent(prop.group, () => []).add(prop);
    }

    final sortedGroupNames = groupedProps.keys.toList()..sort();

    return PanelContainer(
      title: "Properties",
      child: ListView(
        children: sortedGroupNames.map((groupName) {
          final props = groupedProps[groupName]!..sort((a, b) => a.name.compareTo(b.name));
          _expandedGroups.putIfAbsent(groupName, () => true);

          return ExpansionPanelList(
            expansionCallback: (index, isExpanded) {
              setState(() {
                _expandedGroups[groupName] = !isExpanded;
              });
            },
            elevation: 0,
            expandedHeaderPadding: EdgeInsets.zero,
            children: [
              ExpansionPanel(
                canTapOnHeader: true,
                headerBuilder: (context, isExpanded) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    groupName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                body: Column(
                  children: props.map((prop) {
                    final editor = editorRegistry.resolve(prop.type);
                    final value = meta.get(selected!, prop.name);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property name
                          SizedBox(
                            width: 100,
                            child: Text(
                              prop.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Editor widget
                          Expanded(
                            child: editor != null
                                ? editor.buildEditor(
                              label: prop.name,
                              value: value,
                              onChanged: (newVal) {
                                meta.set(selected!, prop.name, newVal);
                                bus.publish(
                                  "property-changed",
                                  PropertyChangeEvent(widget: selected, source: this),
                                );
                              },
                            )
                                : Text("No editor for ${prop.name}"),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                isExpanded: _expandedGroups[groupName]!,
              ),
            ],
          );
        }).toList(),
      ),
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
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DynamicWidget(
                      model: m,
                      meta: widget.metadata[m.type]!,
                    ),
                  ),
                )
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
  final List<WidgetData> models;
  final Map<String, MetaData> metadata;

  const EditorScreen({super.key, required this.models, required this.metadata});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final Environment environment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    environment = Environment(parent: EnvironmentProvider.of(context));
    environment.get<MessageBus>();
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentProvider(
      environment: environment,
      child: Column(
        children: [
          // ===== Toolbar =====
          Container(
            height: 48,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: "Save",
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    // TODO: implement save
                  },
                ),
                IconButton(
                  tooltip: "Revert",
                  icon: const Icon(Icons.undo),
                  onPressed: () {
                    // TODO: implement revert
                  },
                ),
                IconButton(
                  tooltip: "Open",
                  icon: const Icon(Icons.folder_open),
                  onPressed: () {
                    // TODO: implement open
                  },
                ),
                IconButton(
                  tooltip: "Play",
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    // TODO: implement play
                  },
                ),
                const Spacer(),
                // Optional: add extra buttons or status indicators
                Text("Status: Ready", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),

          // ===== Main Editor =====
          Expanded(
            child: Row(
              children: [
                LeftPanelSwitcher(
                  panels: {
                    "tree": WidgetTreePanel(models: widget.models),
                    "palette": WidgetPalette(
                      typeRegistry: environment.get<TypeRegistry>(),
                    ),
                    "json": JsonEditorPanel(),
                  },
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: EditorCanvas(
                          models: widget.models,
                          metadata: widget.metadata,
                        ),
                      ),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade400, width: 0.5),
                          ),
                        ),
                        child: Breadcrumb(
                          items: [
                            BreadcrumbItem(label: "Root", onTap: () {}),
                            BreadcrumbItem(label: "Container", onTap: () {}),
                            BreadcrumbItem(label: "Text", onTap: () {}),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 300, color: Colors.white, child: PropertyPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class WidgetPalette extends StatefulWidget {
  final TypeRegistry typeRegistry;

  const WidgetPalette({super.key, required this.typeRegistry});

  @override
  State<WidgetPalette> createState() => _WidgetPaletteState();
}

class _WidgetPaletteState extends State<WidgetPalette> {
  double _width = 150; // initial width
  static const double _minWidth = 120;
  static const double _maxWidth = 400;

  // Track which groups are expanded
  final Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // initially expand all groups
    for (var group in widget.typeRegistry.metaData.values.map((e) => e.group).toSet()) {
      _expandedGroups[group] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group widgets by group name
    final Map<String, List<MetaData>> groupedWidgets = {};
    for (var meta in widget.typeRegistry.metaData.values) {
      groupedWidgets.putIfAbsent(meta.group, () => []).add(meta);
    }

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _width = (_width + details.delta.dx).clamp(_minWidth, _maxWidth);
        });
      },
      child: Container(
        width: _width,
        color: Colors.grey.shade300,
        child: PanelContainer(
          title: "Palette",
          child: ListView(
            children: groupedWidgets.entries.map((entry) {
              final groupName = entry.key;
              final widgetsInGroup = entry.value;

              return _buildGroup(groupName, widgetsInGroup);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(String groupName, List<MetaData> widgetsInGroup) {
    final isExpanded = _expandedGroups[groupName] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        InkWell(
          onTap: () => setState(() => _expandedGroups[groupName] = !isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 16),
                const SizedBox(width: 4),
                Text(
                  groupName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        // Widgets grid
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = 80.0;
                final crossAxisCount =
                (constraints.maxWidth / itemWidth).floor().clamp(1, 10);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: widgetsInGroup.map((type) {
                    return Draggable<String>(
                      data: type.name,
                      feedback: Material(
                        child: Opacity(
                          opacity: 0.8,
                          child: _buildPaletteItem(type, highlight: true),
                        ),
                      ),
                      child: _buildPaletteItem(type),
                    );
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPaletteItem(MetaData type, {bool highlight = false}) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? Colors.blueAccent : Colors.white,
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.widgets, size: 32), // generic icon
          const SizedBox(height: 4),
          Text(
            type.name,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    var newSelected = identical(event.selection, widget.model);
    if (newSelected != selected) {
      setState(() {
        selected = newSelected;
      });
    }
  }

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bus = EnvironmentProvider.of(context).get<MessageBus>();

    subscription = bus.subscribe<SelectionEvent>(
      "selection",
      (event) => select(event),
    );
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren =
        widget.model is ContainerWidgetData &&
        (widget.model as ContainerWidgetData).children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => bus.publish(
            "selection",
            SelectionEvent(selection: widget.model, source: this),
          ),
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
              children: (widget.model as ContainerWidgetData).children
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
      child: PanelContainer(
        title: "Tree",
        child: ListView(
          children: models
              .map((model) => WidgetTreeNode(model: model))
              .toList(),
        ),
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
