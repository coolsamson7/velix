
import 'package:velix_di/di/di.dart';

import 'editor_builder.dart';

@Injectable()
class PropertyEditorBuilderFactory {
  // instance data

  final Map<Type, PropertyEditorBuilder> _editors = {};

  // public

  void register<T>(PropertyEditorBuilder editor) {
    _editors[T] = editor;
  }

  PropertyEditorBuilder? getBuilder(Type type) {
    var builder = _editors[type];

    return builder;
  }
}