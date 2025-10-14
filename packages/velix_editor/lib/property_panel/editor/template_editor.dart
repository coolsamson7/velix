import 'package:flutter/material.dart';

import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/metadata.dart';


import '../../commands/command_stack.dart';
import '../../metadata/widget_data.dart';
import '../../util/message_bus.dart';
import '../editor_builder.dart';

@Injectable()
class TemplateEditorBuilder extends PropertyEditorBuilder<bool> {
  @override
  Widget buildEditor({
    required Environment environment,
    required MessageBus messageBus,
    required CommandStack commandStack,
    required PropertyDescriptor property,
    required String label,
    required dynamic object,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  }) {
    return WidgetDataField(value: value, onButtonPressed: () {  });
  }
}

class WidgetDataField extends StatelessWidget {
  final WidgetData value;
  final VoidCallback onButtonPressed;

  const WidgetDataField({
    super.key,
    required this.value,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Label showing the type
        Expanded(
          child: Text(
            value.type,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Ellipsis button
        IconButton(
          icon: const Icon(Icons.more_horiz),
          tooltip: 'More options',
          onPressed: onButtonPressed,
        ),
      ],
    );
  }
}
