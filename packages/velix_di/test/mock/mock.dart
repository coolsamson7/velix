import 'package:velix_di/di/di.dart';

import '../di.dart';

@Module(imports: [TestModule], includeSubdirectories: false, includeSiblings: false)
class MockModule {
}

@Injectable(replace: true)
class MockBase extends ConditionalBase {
  MockBase();
}