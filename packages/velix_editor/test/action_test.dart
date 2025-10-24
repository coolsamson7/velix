import 'dart:convert';
import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/validation/validation.dart';

import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/actions/action_parser.dart';

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_editor/actions/autocomplete.dart';
import 'package:velix_editor/actions/eval.dart';
import 'package:velix_editor/actions/expressions.dart';
import 'package:velix_editor/actions/infer_types.dart';
import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/editor.dart';
import 'package:velix_editor/editor_module.dart';
import 'package:velix_ui/velix_ui.types.g.dart';

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
    print("hello $message");
    return "hello $message";
  }
}


@Injectable()
@Dataclass()
class Page {
  // instance data

  @Attribute()
  final User user;
  @Attribute()
  final List<User> users;

  // constructor

  Page() : user = User(name: "andi", address: Address(city: "Köln", street: "Neumarkt")),
  users = [
    User(name: "andi", address: Address(city: "Köln", street: "Neumarkt")),
    User(name: "nika", address: Address(city: "Köln", street: "Neumarkt"))];

  // methods

  @Method()
  List<User> getUsers() {
    return users;
  }
}

@Module(imports: [EditorModule], includeSiblings: false, includeSubdirectories: false)
class TestModule {}

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String> getApplicationSupportPath() async => '';
}


void main() {
  PathProviderPlatform.instance = FakePathProviderPlatform();

  WidgetsFlutterBinding.ensureInitialized();

  // register types

  EditorModule.boot;

  registerTypes();

  // boot environment

  var environment = Environment(forModule: EditorModule);
  var page = environment.get<Page>();
  
  var registry = ClassRegistry();

  String json = "";

  Future<void> load() async {
    if (json.isEmpty) {
      final file = File('test/resources/action_test.types.g.json');
      json = await file.readAsString();
    }
  }

  setUpAll(() async {
    await load();
  });


  // parser tests

  group('json', () {
    test('parse ', () async {
      await load();

      final Map<String, dynamic> data = jsonDecode(json);
      
      registry.read(data["classes"]);

      var getUsers = registry.getClass("Page").find("getUsers") as MethodDesc;

      var returnType = getUsers.type;
      if ( returnType.isList()) {
        var elementType = (returnType as ListDesc).elementType;

        print(elementType);
      }

      print(registry);
    });
  });

  group('parser', () {
    var parser = ActionParser.instance;

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
    var parser = ActionParser.instance;

    final checker = TypeChecker(RuntimeTypeTypeResolver(root: TypeDescriptor.forType(Page)));
    final context =  TypeCheckerContext<RuntimeTypeInfo>();

    Expression parse(String code) {
      var expression = parser.parse(code);

      expression.accept(checker, context);

      return expression;
    }

    test('literals ', () {
      // int

      var expression = parse("1");

      expect(expression.getType<AbstractType>().type, equals(int));

      // bool

      expression = parse("true");

      expect(expression.getType<AbstractType>().type, equals(bool));

      // double

      expression = parse("1.1");

      expect(expression.getType<AbstractType>().type, equals(double));

      // string

      expression = parse("\"\"");

      expect(expression.getType<AbstractType>().type, equals(String));
    });

    test('unary ', () {
      // -
      var expression = parse("-1");

      expect(expression.getType<AbstractType>().type, equals(int));

      // !
      expression = parse("!true");

      expect(expression.getType<AbstractType>().type, equals(bool));
    });

    test('binary ', () {
      // +, -, *, /, %
      // &&
      // <, <=, ==, >, >=

      // arithmetic

      var expression = parse("1 + 2");

      expect(expression.getType<AbstractType>().type, equals(int));

      // logic

      expression = parse("true && false");

      expect(expression.getType<AbstractType>().type, equals(bool));

      // comparison

      expression = parse("1 < 2");

      expect(expression.getType<AbstractType>().type, equals(bool));
    });

    test('index ', () {
      var code = "users[0]";

      var expression = parse(code);

      expect(expression.getType<AbstractType>().type, equals(User));
    });

    /* TODO test('conditional ', () {
      var expression = parse("1 > 0 ? true : false");

      expect(expression.getType<AbstractType>().type, equals(bool));
    })*/;

    test('methods ', () {
      var expression = parse("getUsers()");

      expect(expression.getType<AbstractType>().type, equals(List<User>));
    });

    test('wrong parameter number ', () {
      expect(() {
        parse("user.hello()");
      }, throwsA(isA<Exception>()));
    });

    test('wrong parameter type ', () {
      var code = "user.hello(1)";

      var expression = parser.parse(code);
      expect(() {
        expression.accept(checker, context);
      }, throwsA(isA<Exception>()));
    });
  });

  // auto completion

  group('autocompletion', () {
    late Map<String, dynamic> data;// = jsonDecode(json);

    //registry.read(data["classes"]);

    late Autocomplete autocomplete;// = Autocomplete(typeChecker: TypeChecker(ClassDescTypeResolver(root: registry.getClass("Page"))));

    setUpAll(() async {
      await load();
      data = jsonDecode(json);
      registry.read(data["classes"]);
      autocomplete = Autocomplete(typeChecker: TypeChecker(ClassDescTypeResolver(root: registry.getClass("Page"), variables: {})));

    });
    
    test('variable ', () {
      var suggestions = autocomplete.suggest("a");

      expect(suggestions.length, equals(0));

      suggestions = autocomplete.suggest("u");

      expect(suggestions.length, equals(2));

      suggestions = autocomplete.suggest("user");

      expect(suggestions.length, equals(0));

      suggestions = autocomplete.suggest("user.");

      expect(suggestions.length, equals(3));

      suggestions = autocomplete.suggest("user.h");

      expect(suggestions.length, equals(1));

      suggestions = autocomplete.suggest("user.address.");

      expect(suggestions.length, equals(3));

      suggestions = autocomplete.suggest("user.hello(user.)", cursorOffset: 15);

      expect(suggestions.length, equals(3));
    });
  });

  // evaluator tests

  group('evaluator', () {
    dynamic eval(String expression, dynamic instance) {
      TypeDescriptor contextType = TypeDescriptor.forType(instance.runtimeType);
      var result = ActionParser.instance.parseStrict(expression, typeChecker: TypeChecker(RuntimeTypeTypeResolver(root: contextType)));

      // compute call

      var visitor = EvalVisitor(contextType);

      var call = result.value!.accept(visitor, CallVisitorContext(instance: instance));

      // eval

      return call.eval(instance, EvalContext(instance: instance, variables: {}));
    }

    // register types

    test('eval literal ', () {
      // number

      var value = eval("1", page);

      expect(value, equals(1));

      // bool

      value = eval("true", page);

      expect(value, equals(true));

      // string

      value = eval("\"true\"", page);

      expect(value, equals("true"));
    });

    test('eval variable ', () {
      // number

      var value = eval("user", page);

      expect(value, equals(page.user));
    });

    test('eval unary ', () {
      // number

      var value = eval("-1", page);

      expect(value, equals(-1));

      // bool

      value = eval("!true", page);

      expect(value, equals(false));
    });

    test('eval binary ', () {
      // number

      var value = eval("1 + 1", page);

      expect(value, equals(2));

      // bool

      value = eval("true && false", page);

      expect(value, equals(false));

      // string

      value = eval("1 < 2", page);

      expect(value, equals(true));
    });

    test('eval condition ', () {
      // number

      //TODO var value = eval("2 > 1 ? true : false", page);

      //expect(value, equals(true));
    });

    test('eval index ', () {
      // number

      var value = eval("users[0]", page);

      expect(value is User, equals(true));
    });

    //

    test('eval member ', () {
      var value = eval("user.name", page);

      expect(value, equals("andi"));
    });

    test('eval recursive member ', () {
      var value = eval( "user.address.city", page);

      expect(value, equals("Köln"));
    });

    test('eval method call with literal arg', () {
      var value = eval("user.hello(\"world\")", page);

      expect(value, equals("hello world"));
    });

    test('eval method call with complex arg', () {
      var value = eval("user.hello(user.name)", page);

      expect(value, equals("hello andi"));
    });
  });
}