import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import '../commands/command_stack.dart';
import '../metadata/metadata.dart';
import '../util/message_bus.dart';
import 'editor_builder.dart';
import 'editor_registry.dart';

@Injectable()
class ListPropertyEditor extends PropertyEditorBuilder<List> {
  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required dynamic object,
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    final elementType = TypeDescriptor.forType(property.field.elementType);
    final containerFactory = property.field.factoryConstructor!;
    var items = value ?? containerFactory();

    void addItem() {
      var newItems = containerFactory();
      newItems.addAll(items);
      newItems.add(elementType.constructor!());
      onChanged(items = newItems);
    }

    void deleteItem(item) {
      var newItems = containerFactory();
      newItems.addAll(items);
      newItems.remove(item);
      onChanged(items = newItems);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
              tooltip: "Add item",
              onPressed: addItem,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < items.length; i++)
              _HoverableListItem(
                child: _buildElementEditor(
                  environment: environment,
                  messageBus: messageBus,
                  commandStack: commandStack,
                  property: property,
                  object: object,
                  elementType: elementType.type,
                  value: items[i],
                  onChanged: (newVal) {
                    items[i] = newVal;
                    onChanged(items);
                  },
                ),
                onRemove: () => deleteItem(items[i]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildElementEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required dynamic object,
    required dynamic value,
    required Type elementType,
    required ValueChanged<dynamic> onChanged,
  }) {
    final registry = environment.get<PropertyEditorBuilderFactory>();
    final editor = registry.getBuilder(elementType);

    if (editor != null) {
      return editor.buildEditor(
        environment: environment,
        messageBus: messageBus,
        commandStack: commandStack,
        label: "",
        object: object,
        property: property,
        value: value,
        onChanged: onChanged,
      );
    }

    return Text("No editor for $elementType");
  }
}

class _HoverableListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _HoverableListItem({
    required this.child,
    required this.onRemove,
  });

  @override
  State<_HoverableListItem> createState() => _HoverableListItemState();
}

class _HoverableListItemState extends State<_HoverableListItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        // Removed vertical padding between items
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: widget.child),
            if (_hovering)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                tooltip: "Remove item",
                onPressed: widget.onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
