import 'package:flutter_test/flutter_test.dart';

import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/actions/action_evaluator.dart';
import 'package:velix_editor/actions/action_parser.dart';

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/parser.dart';
import 'package:velix_editor/actions/types.dart';

import 'action_test.types.g.dart';

@Dataclass()
class TestUser {
  // instance data

  @Attribute()
  String name = "";

  // constructor

  TestUser({required this.name});

  // methods

  @Inject()
  String hello() {
    return "world";
  }
}


@Injectable()
@Dataclass()
class TestPage {
  // instance data

  @Attribute()
  final TestUser user;

  // constructor

  TestPage() : user = TestUser(name: "andi");

  // methods

  @Inject()
  void setup() {
    print("setup");
  }
}

// Nested class type
final innerClass = ClassDesc('Inner',
  properties: {
    'value': FieldDesc('value', ClassDesc.int_type),
    'doubleValue': MethodDesc('doubleValue', [], ClassDesc.double_type)
  },
);

// Root class
final rootClass = ClassDesc('Root',
  properties: {
    'x': FieldDesc('x', ClassDesc.int_type),
    'inner': FieldDesc('inner', innerClass),
    'sum': MethodDesc('sum', [ClassDesc.int_type, ClassDesc.int_type], ClassDesc.int_type),
  },
);

//

final pageClass = ClassDesc('Page',
    properties: {
      'user': FieldDesc('xúser', userClass),
    }
);

final userClass = ClassDesc('User',
  properties: {
    'name': FieldDesc('value', ClassDesc.string_type),
    'hello': MethodDesc('hello', [], ClassDesc.string_type)
  },
);


@Module(includeSiblings: false, includeSubdirectories: false)
class TestModule {}

void main() {
  // register types

  Velix.bootstrap;

  registerTypes();

  // boot environment

  var environment = Environment(forModule: TestModule);
  var page = environment.get<TestPage>();

  // parser tests

  group('parser', () {
    var parser = ActionParser();

    test('parse member ', () {
      var code = "user.name";

      var expression = parser.parse(code);

      expect(expression, isNotNull);
    });

    test('parse method ', () {
      var code = "user.hello()";

      var expression = parser.parse(code);

      expect(expression, isNotNull);
    });
  });

  // evaluator tests

  group('evaluator', () {
    var evaluator = ActionEvaluator(contextType: TypeDescriptor.forType(TestPage));

    // register types

    test('eval member ', () {
      var value = evaluator.call( "user.name", page);

      expect(value, equals("andi"));
    });

    test('eval method call', () {
      var value = evaluator.call("user.hello()", page);

      expect(value, equals("world"));
    });
  });
}