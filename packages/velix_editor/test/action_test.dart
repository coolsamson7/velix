import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';

import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/actions/action_evaluator.dart';
import 'package:velix_editor/actions/action_parser.dart';

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/autocomplete.dart';
import 'package:velix_editor/actions/eval.dart';
import 'package:velix_editor/actions/expressions.dart';
import 'package:velix_editor/actions/infer_types.dart';
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


// Primitive types



// Nested class type
final innerClass = ClassDesc(
  'Inner',
  properties: {
    'value': FieldDesc('value', classInt),
    'doubleValue': MethodDesc('doubleValue', [], classInt)
  },
);

// Root class
final rootClass = ClassDesc(
  'Root',
  properties: {
    'x': FieldDesc('x', classInt),
    'inner': FieldDesc('inner', innerClass),
    'sum': MethodDesc('sum', [classInt, classInt], classInt),
  },
);

//

final pageClass = ClassDesc(
    'Page',
    properties: {
      'user': FieldDesc('xúser', userClass),
    }
);

final userClass = ClassDesc(
  'User',
  properties: {
    'name': FieldDesc('value', classString),
    'hello': MethodDesc('hello', [], classString)
  },
);


@Module(includeSiblings: false, includeSubdirectories: false)
class TestModule {}

void main() {
  // register types

  Velix.bootstrap;

  registerTypes();

  var environment = Environment(forModule: TestModule);
  var page = environment.get<TestPage>();

  final parser = ExpressionParser();

/*  group('new', () {

    test("test", () {
      var input = 'inner.doubleValue()';
      var result = parser.expression.parse(input);
      var resolver = ClassDescTypeResolver(root: rootClass);

      if (result is Success<Expression>) {
        final expr = result.value;
        print('Parsed: $expr');
        print('Start: ${expr.start}, End: ${expr.end}');
        final inferencer = TypeInferencer(resolver);
        final type = expr.accept(inferencer);
        print('Inferred type: ${type}');
      }
      else {
        print('Parse error at position ${result.position}');
      }

      // autohotkey

      input = "inn";
      result = parser.expression.parse(input);

      if (result is Success<Expression>) {
        final expr = result.value;
        final cursorOffset = input.length; // cursor at end
        final autocomplete = Autocomplete(rootClass);

        final suggestions = autocomplete.suggest(expr, cursorOffset, input);
        print('Suggestions: $suggestions');
        // Expected output: ['value', 'doubleValue']
      }
    });
  });*/

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

  group('evaluator', () {

    var parser = ActionParser();
    var evaluator = ActionEvaluator(contextType: TypeDescriptor.forType(TestPage));

    // register types

    test('parse member ', () {
      var code = "user.name";

      var value = evaluator.call( "user.name", page);

      expect(value, equals("andi"));
    });

    test('parse method ', () {
      var code = "user.hello()";

      var value = evaluator.call("user.hello()", page);

      expect(value, equals("world"));
    });
  });
}