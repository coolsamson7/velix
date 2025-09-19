

//@Module(imports: [])
import 'package:velix_di/di/di.dart';

class EditorModule {
  @OnInit()
  void onInit() {
    print("EditorModule.onInit()");
  }

  @OnDestroy()
  void onDestroy() {
    print("EditorModule.onDestroy()");
  }
}
