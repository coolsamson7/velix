import 'package:velix_di/di/di.dart';

@Module()
class ConflictModule {
  @Create()
  Conflict create() {
    return Conflict();
  }
}

@Injectable()
class Conflict {
  const Conflict();
}