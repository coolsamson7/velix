import 'package:flutter_test/flutter_test.dart';

import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/actions/action_evaluator.dart';
import 'package:velix_editor/actions/action_parser.dart';

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/autocomplete.dart';
import 'package:velix_editor/actions/types.dart';

import 'action_test.types.g.dart';

@Dataclass()
class Address {
  // instance data

  @Attribute()
  String city = "";
  @Attribute()
  String street = "";

  // constructor

  Address({required this.city, required this.street});

  // methods

  @Inject()
  String hello(String message, ) {
    return "world";
  }
}

@Dataclass()
class User {
  // instance data

  @Attribute()
  String name = "";
  @Attribute()
  Address address;

  // constructor

  User({required this.name, required this.address});

  // methods

  @Inject()
  String hello(String message) {
    return "hello $message";
  }
}


@Injectable()
@Dataclass()
class Page {
  // instance data

  @Attribute()
  final User user;

  // constructor

  Page() : user = User(name: "andi", address: Address(city: "Köln", street: "Neumarkt"));

  // methods

  @Inject()
  void setup() {
    print("setup");
  }
}

// same thing

final pageClass = ClassDesc('Page',
    properties: {
      'user': FieldDesc('user', userClass),
    }
);

final userClass = ClassDesc('User',
  properties: {
    'name': FieldDesc('value', ClassDesc.string_type),
    'address': FieldDesc('address',  addressClass)
  },
);

final addressClass = ClassDesc('Address',
  properties: {
    'city': FieldDesc('city', ClassDesc.string_type),
    'street': FieldDesc('street', ClassDesc.string_type),
    'hello': MethodDesc('hello', [ClassDesc.string_type], ClassDesc.string_type)
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
  var page = environment.get<Page>();

  // parser tests

  group('parser', () {
    var parser = ActionParser();

    test('parse member ', () {
      var code = "user.name";

      var expression = parser.parse(code);

      expect(expression, isNotNull);
    });

    test('parse recursive member ', () {
      var code = "user.address.city";

      var expression = parser.parse(code);

      expect(expression, isNotNull);
    });

    test('parse method ', () {
      var code = "user.hello(\"world\")";

      var expression = parser.parse(code);

      expect(expression, isNotNull);
    });
  });

  // auto completion

  group('autocompletion', () {
    var autocomplete = Autocomplete(pageClass);
    
    test('variable ', () {
      var suggestions = autocomplete.suggest("user");

      suggestions = autocomplete.suggest("user");

      suggestions = autocomplete.suggest("user.");

      suggestions = autocomplete.suggest("user.c");

      print("suggestions");
      //expect(value, equals("andi"));
    });
  });

  // evaluator tests

  group('evaluator', () {
    var evaluator = ActionEvaluator(contextType: TypeDescriptor.forType(Page));

    // register types

    test('eval member ', () {
      var value = evaluator.call( "user.name", page);

      expect(value, equals("andi"));
    });

    test('eval recursive member ', () {
      var value = evaluator.call( "user.address.city", page);

      expect(value, equals("Köln"));
    });

    test('eval method call with literal arg', () {
      var value = evaluator.call("user.hello(\"world\")", page);

      expect(value, equals("hello world"));
    });

    test('eval method call with complex arg', () {
      var value = evaluator.call("user.hello(user.name)", page);

      expect(value, equals("hello andi"));
    });
  });
}