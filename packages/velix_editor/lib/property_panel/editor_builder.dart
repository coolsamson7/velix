import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

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
    required String label,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
  });
}