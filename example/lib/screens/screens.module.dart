import 'package:velix/di/di.dart';

@Module(imports: [])
class ScreensModule {
  @OnDestroy()
  void onDestroy() {
    print("ScreensModule.onDestroy");
  }
}

@Injectable()
class Foo {
  Foo();

  @OnDestroy()
  void onDestroy() {
    print("Foo.onDestroy");
  }
}

@Injectable(scope: "environment")
class Bar {
  Bar();

  @OnDestroy()
  void onDestroy() {
    print("Bar.onDestroy");
  }
}