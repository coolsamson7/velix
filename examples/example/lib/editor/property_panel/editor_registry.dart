
import 'package:velix_di/di/di.dart';

import 'editor_builder.dart';

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