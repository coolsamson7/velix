import 'package:flutter/material.dart' hide MetaData;
import 'package:sample/editor/editor/panel_switcher.dart';
import 'package:sample/editor/editor/widget_breadcrumb.dart';
import 'package:velix_di/di/di.dart';


import '../json/json_view.dart';
import '../metadata/metadata.dart';
import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';
import '../palette/palette_view.dart';
import '../property_panel/panel.dart';
import '../provider/environment_provider.dart';
import '../tree/tree_view.dart';
import '../util/message_bus.dart';
import 'canvas.dart';

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
                        child: WidgetBreadcrumbWidget(),
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