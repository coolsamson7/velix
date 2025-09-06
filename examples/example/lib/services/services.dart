import 'package:velix_di/velix_di.dart';

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

/// sample for an object that will be recreated on every level
@Injectable(scope: "environment")
class PerWidgetState {
  PerWidgetState();

  @OnInit()
  void onInit() {
    print("PerWidgetState.onInit()");
  }

  @OnDestroy()
  void onDestroy() {
    print("PerWidgetState.onDestroy()");
  }
}

