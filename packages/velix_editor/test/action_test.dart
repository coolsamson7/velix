import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/actions/action_evaluator.dart';
import 'package:velix_editor/actions/action_parser.dart';

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/autocomplete.dart';
import 'package:velix_editor/actions/infer_types.dart';
import 'package:velix_editor/actions/types.dart';

import 'action_test.types.g.dart';

String json = '''
{
  "classes": [
    {
      "name": "Address",
      "superClass": null,
      "properties": [
        {
          "name": "city",
          "type": "String",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        },
        {
          "name": "street",
          "type": "String",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        }
      ],
      "methods": [
        {
          "name": "hello",
          "parameters": [
            {
              "name": "message",
              "type": "String",
              "isNamed": false,
              "isRequired": true,
              "isNullable": false
            }
          ],
          "returnType": "String",
          "isAsync": false,
          "annotations": [
            {
              "name": "Inject",
              "value": "Inject"
            }
          ]
        }
      ],
      "annotations": [
        {
          "name": "Dataclass",
          "value": "Dataclass"
        }
      ],
      "isAbstract": false,
      "location": "13:1"
    },
    {
      "name": "User",
      "superClass": null,
      "properties": [
        {
          "name": "name",
          "type": "String",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        },
        {
          "name": "address",
          "type": "Address",
          "isNullable": false,
          "isFinal": false,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        }
      ],
      "methods": [
        {
          "name": "hello",
          "parameters": [
            {
              "name": "message",
              "type": "String",
              "isNamed": false,
              "isRequired": true,
              "isNullable": false
            }
          ],
          "returnType": "String",
          "isAsync": false,
          "annotations": [
            {
              "name": "Inject",
              "value": "Inject"
            }
          ]
        }
      ],
      "annotations": [
        {
          "name": "Dataclass",
          "value": "Dataclass"
        }
      ],
      "isAbstract": false,
      "location": "34:1"
    },
    {
      "name": "Page",
      "superClass": null,
      "properties": [
        {
          "name": "user",
          "type": "User",
          "isNullable": false,
          "isFinal": true,
          "annotations": [
            {
              "name": "Attribute",
              "value": "Attribute"
            }
          ]
        }
      ],
      "methods": [
        {
          "name": "setup",
          "parameters": [],
          "returnType": "void",
          "isAsync": false,
          "annotations": [
            {
              "name": "Inject",
              "value": "Inject"
            }
          ]
        }
      ],
      "annotations": [
        {
          "name": "Injectable",
          "value": "Injectable"
        },
        {
          "name": "Dataclass",
          "value": "Dataclass"
        }
      ],
      "isAbstract": false,
      "location": "56:1"
    },
    {
      "name": "TestModule",
      "superClass": null,
      "properties": [],
      "methods": [],
      "annotations": [
        {
          "name": "Module",
          "value": "Module"
        }
      ],
      "isAbstract": false,
      "location": "100:1"
    }
  ]
}
''';

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

@Module(includeSiblings: false, includeSubdirectories: false)
class TestModule {}

void main() {
  // register types

  Velix.bootstrap;

  registerTypes();

  // boot environment

  var environment = Environment(forModule: TestModule);
  var page = environment.get<Page>();
  
  var registry = ClassRegistry();

  // parser tests

  group('json', () {
    test('parse ', () {
      final Map<String, dynamic> data = jsonDecode(json);
      
      registry.read(data["classes"]);
    });
  });

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

  group('type checker', () {
    var parser = ActionParser();

    final checker = TypeChecker(RuntimeTypeTypeResolver(root: TypeDescriptor.forType(Page)));

    test('wrong parameter number ', () {
      var code = "user.hello()";

      var expression = parser.parse(code);

      expect(() {
        expression.accept(checker);
      }, throwsA(isA<Exception>()));
    });

    test('wrong parameter type ', () {
      var code = "user.hello(1)";

      var expression = parser.parse(code);
      expect(() {
        expression.accept(checker);
      }, throwsA(isA<Exception>()));
    });
  });

  // auto completion

  group('autocompletion', () {
    final Map<String, dynamic> data = jsonDecode(json);

    registry.read(data["classes"]);

    var autocomplete = Autocomplete(registry.getClass("Page"));
    
    test('variable ', () {
      var suggestions = autocomplete.suggest("a");

      expect(suggestions.length, equals(0));

      suggestions = autocomplete.suggest("u");

      expect(suggestions.length, equals(1));

      suggestions = autocomplete.suggest("user");

      expect(suggestions.length, equals(0));

      suggestions = autocomplete.suggest("user.");

      expect(suggestions.length, equals(3));

      suggestions = autocomplete.suggest("user.h");

      expect(suggestions.length, equals(1));

      suggestions = autocomplete.suggest("user.address.");

      expect(suggestions.length, equals(3));
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