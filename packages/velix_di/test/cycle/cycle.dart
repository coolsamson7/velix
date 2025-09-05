import 'package:velix_di/di/di.dart';

@Module()
class CycleModule {
}

@Injectable()
class CycleSource {
  const CycleSource(CycleTarget target);
}

@Injectable()
class CycleTarget {
  const CycleTarget(CycleSource source);
}