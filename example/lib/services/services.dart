import 'package:velix/di/di.dart';

@Injectable()
class TodoService {
  TodoService();

  @OnInit()
  void onInit() {
    print("TodoService.onInit()");
  }

  @OnDestroy()
  void onDestroy() {
    print("TodoService.onDestroy()");
  }
}

@Module(imports: [])
class ServiceModule {
  @OnInit()
  void onInit() {
    print("ServiceModule.onInit()");
  }

  @OnDestroy()
  void onDestroy() {
    print("ServiceModule.onDestroy()");
  }
}

