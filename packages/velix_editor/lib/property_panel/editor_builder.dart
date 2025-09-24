import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import '../commands/command_stack.dart';
import '../util/message_bus.dart';
import 'editor_registry.dart';

@Injectable()
abstract class PropertyEditorBuilder<T> {
  // lifecycle

  @Inject()
  void setup(PropertyEditorBuilderFactory registry) {
    registry.register<T>(this);
  }

  // abstract

  Widget buildEditor({
    required MessageBus messageBus,
    required CommandStack commandStack,
    required FieldDescriptor property,
    required dynamic object,
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  });
}