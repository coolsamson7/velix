import 'package:velix_di/di/di.dart';
import 'package:velix_ui/module.dart';

import 'editor.types.g.dart';

@Module(imports: [UIModule])
class EditorModule {
  static final Type boot = _init<EditorModule>();

  static Type _init<T>() {
    registerEditorTypes();

    UIModule.boot;

    return T;
  }
}
