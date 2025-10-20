import 'package:velix_di/velix_di.dart';
import 'package:velix_ui/velix_ui.types.g.dart';

@Module(imports: [])
class UIModule {
  static final Type boot = _init<UIModule>();

  static Type _init<T>() {
    registerUITypes();

    Velix.bootstrap;

    return T;
  }

  @OnInit()
  void onInit() {
    print("UIModule.onInit()");
  }

  @OnDestroy()
  void onDestroy() {
    print("UIModule.onDestroy()");
  }
}