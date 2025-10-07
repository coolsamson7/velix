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
  // override

  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required dynamic object,
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged, // TODO usage!
  }) {
    final elementType = TypeDescriptor.forType(property.field.elementType);
    final items = value ?? property.field.factoryConstructor!();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
              tooltip: "Add item",
              onPressed: () {
                final newItem = elementType.constructor!();
                items.add(newItem);
                onChanged(items);
              },
            ),
          ],
        ),
        Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                      tooltip: "Remove item",
                      onPressed: () {
                        items.removeAt(i);
                        onChanged(items);
                      },
                    ),
                  ],
                ),
              ),
            ],
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

    /* if the element is compound (struct/object)
    if (TypeDescriptor.hasType(elementType)) {
      return CompoundPropertyEditor(
        property: property,
        label: "", // element, so no label
        target: object,
        descriptor: TypeDescriptor.of(elementType),
        value: value,
        editorRegistry: registry,
        bus: messageBus,
        commandStack: commandStack,
      );
    }*/

    // otherwise use a primitive editor
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
