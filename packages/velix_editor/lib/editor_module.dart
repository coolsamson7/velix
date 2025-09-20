import 'package:velix_di/di/di.dart';

import 'editor.types.g.dart';

@Module(imports: [])
class EditorModule {
  static final Type boot = _init<EditorModule>();

  static Type _init<T>() {
    registerEditorTypes();

    return T;
  }

  EditorModule();

  @OnInit()
  void onInit() {
    print("EditorModule.onInit()");

    //registerEditorTypes();
  }

  @OnDestroy()
  void onDestroy() {
    print("EditorModule.onDestroy()");
  }
}
