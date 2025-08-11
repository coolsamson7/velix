import '../reflectable/reflectable.dart';

typedef Check<T> = bool Function(T);

class Test<T> {
  final Type type;
  final String name;
  final bool stop;
  bool ignore;
  final Map<String, dynamic> params;
  final Check<T> check;

  // constructor

  Test({required this.type, required this.name, required this.check,this.params = const <String, dynamic>{}, this.stop = false, this.ignore = false});

  // public

  bool run(dynamic object) {
    if (object is T) {
      return check(object);
    }
    return false; // or true if you want to skip silently
  }
}

typedef MethodApplier<T> = void Function(AbstractType<T>, List<dynamic> args);

enum ArgType {
  string_type,
  int_type,
  double_type;

  dynamic parse(String value) {
    switch (this) {
      case ArgType.string_type:
        return value;
      case ArgType.int_type:
        return int.parse(value);
      case ArgType.double_type:
        return double.parse(value);
    }
  }

  String get name => toString().split('.').last;
}

class MethodSpec {
  final int argCount;
  final List<ArgType> argTypes;
  final MethodApplier<dynamic> apply;

  const MethodSpec(this.argCount, this.argTypes, this.apply);
}


class AbstractType<T> {
  late Type type;
  List<Test<dynamic>> tests = [];

  // constructor

  AbstractType({required this.type});

  // internal

  AbstractType constraint(String input){
    return this;
  }

  void parse(Map<String, MethodSpec> methods, String expression) {
    final tokens = expression.split(RegExp(r'\s+'));

    for (int i = 0; i < tokens.length;) {
      final name = tokens[i];
      final args = <dynamic>[];
      i++;

      final spec = methods[name];
      if (spec == null) throw ArgumentError('Unknown method: $name');

      for (int j = 0; j < spec.argCount && i < tokens.length; j++) {
        final type = spec.argTypes[j];
        try {
          args.add(type.parse(tokens[i]));
        }
        catch (e) {
          throw ArgumentError('Invalid argument for $name: ${tokens[i]} is not a valid ${type.name}');
        }

        i++;
      }

      if (args.length < spec.argCount) {
        throw ArgumentError('Missing arguments for $name: expected ${spec.argCount}, got ${args.length}');
      }

      spec.apply(this, args);
    }
  }

  // create the code

  String code() {
    final buffer = StringBuffer();

    var index = 0;
    for (final test in tests) {
      final name = test.name;
      final params = test.params;

      if (index == 0) {
        buffer.write(runtimeType.toString());
        buffer.write("()");
      }
      else {
        buffer.write('.$name');

        if (params.isNotEmpty) {
          final formatted = params.entries
              .map((e) => _formatParam(e.value))
              .join(', ');
          buffer.write('($formatted)');
        }
      }

      index++;
    } // for

    return buffer.toString();
  }

  String _formatParam(dynamic value) {
    if (value is String) return '"$value"';
    return '$value';
  }



  void check(dynamic object, ValidationContext context) {
    for ( Test test in tests) {
      if (!test.run(object)) {
        if (!test.ignore)
          context.addViolation(
            type: test.type,
            name: test.name,
            params: test.params,
            path: context.path,
            value: object,
            message: ""//test.message
          );

        if ( test.stop) {
          break;
        }
      }
    }
  }

  AbstractType<T> test<S>({required Type type, required String name, required Check<S> check, params = const <String, dynamic>{}, stop = false, ignore = false}) {
    tests.add(Test<S>(
        type: type,
        name: name,
        params: params,
        check: check,
        stop: stop,
        ignore: ignore
    ));

    return this;
  }

  // fluent

  void baseType<T>(Type type) {
    this.type = type;

    this.test<dynamic>(
        type: type,
        name: "type",
        params: {
          "type": type
        },
        check: (dynamic object) => object is T,
        stop: true
    );
  }

  AbstractType<T> required() {
    var typeTest = this.tests[0];

    typeTest.ignore = false;

    return this;
  }

  AbstractType<T> optional()  {
    var typeTest = this.tests[0];

    typeTest.ignore = true;

    return this;
  }

  // public

  void validate(dynamic object) {
    ValidationContext context = ValidationContext();

    check(object, context);

    if (context.hasViolations) {
      throw ValidationException(violations: context.violations);
    }
  }

  bool isValid(dynamic object) {
    ValidationContext context = ValidationContext();

    check(object, context);

    return !context.hasViolations;
  }
}

class ValidationException {
  List<TypeViolation> violations;

  ValidationException({required this.violations});

  @override
  String toString() {
    var buffer = StringBuffer();

    for ( var violation in violations)
      buffer.writeln(violation.toString());

    return buffer.toString();
  }
}

class TypeViolation {
  final Type type;
  final String name;
  final Map<String, dynamic> params;
  final dynamic value;
  final String path;
  final String message;

   const TypeViolation({
     required this.type,
     required this.name,
     required this.params,
     required this.value,
     required this.path,
     required this.message});

   @override
   String toString() {
     var buffer = StringBuffer();

     Map<String, String> stringMap = params.map(
           (key, value) => MapEntry(key, value.toString()),
     );

     var translation = "validation.${type.toString().toLowerCase()}.$name";//TODO .tr(namedArgs: stringMap);

     buffer.write(translation);

     return buffer.toString();
   }
}

class ValidationContext {
  // instance data

  final List<TypeViolation> violations = [];
  String path = "";

  // public

  void addViolation({ required Type type,
    required String name,
    required Map<String, dynamic> params,
    required dynamic value,
    required String path,
    String message = ""}) {
    violations.add(TypeViolation(
      type: type,
      name: name,
      params: params,
      value: value,
      path: path,
      message: message,
    ));
  }

  bool get hasViolations => violations.isNotEmpty;
}

// number

class IntType extends AbstractType<int> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'min': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).min(a[0])),
    'max': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).max(a[0])),
    'lessThan': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).lessThan(a[0])),
    'lessThanEquals': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).lessThanEquals(a[0])),
    'greaterThan': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).greaterThan(a[0])),
    'greaterThanEquals': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).greaterThanEquals(a[0]))
  };

  // static methods

  static IntType fromString(String input) {
    var result = IntType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  IntType() : super(type: int) {
    baseType<int>(int);
  }

  // fluent

  IntType required() {
    super.required();

    return this;
  }

  IntType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }

  IntType min(int length) {
    test<int>(
      type: int,
      name: "min",
      params: {
        "min": length
      },
      check: (obj) => obj >= length,
    );

    return this;
  }

  IntType max(int length) {
    test<int>(
      type: int,
      name: "max",
      params: {
        "max": length
      },
      check: (obj) => obj <= length,
    );

    return this;
  }

  IntType lessThan(int length) {
    test<int>(
      type: int,
      name: "lessThan",
      params: {
        "lessThan": length
      },
      check: (obj) => obj < length,
    );

    return this;
  }

  IntType lessThanEquals(int length) {
    test<int>(
      type: int,
      name: "lessThanEquals",
      params: {
        "lessThanEquals": length
      },
      check: (obj) => obj <= length,
    );

    return this;
  }

  IntType greaterThan(int length) {
    test<int>(
      type: int,
      name: "greaterThan",
      params: {
        "greaterThan": length
      },
      check: (obj) => obj > length,
    );

    return this;
  }

  IntType greaterThanEquals(int length) {
    test<int>(
      type: int,
      name: "greaterThanEquals",
      params: {
        "greaterThanEquals": length
      },
      check: (obj) => obj >= length,
    );

    return this;
  }
}

// double

class DoubleType extends AbstractType<double> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'min': MethodSpec(1, [ArgType.double_type], (t, a) => (t as dynamic).min(a[0])),
    'max': MethodSpec(1, [ArgType.double_type], (t, a) => (t as dynamic).max(a[0])),
    'lessThan': MethodSpec(1, [ArgType.double_type], (t, a) => (t as dynamic).lessThan(a[0])),
    'lessThanEquals': MethodSpec(1, [ArgType.double_type], (t, a) => (t as dynamic).lessThanEquals(a[0])),
    'greaterThan': MethodSpec(1, [ArgType.double_type], (t, a) => (t as dynamic).greaterThan(a[0])),
    'greaterThanEquals': MethodSpec(1, [ArgType.double_type], (t, a) => (t as dynamic).greaterThanEquals(a[0]))
  };

  // static methods

  static DoubleType fromString(String input) {
    var result = DoubleType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  DoubleType() : super(type: double) {
    baseType<double>(double);
  }

  // fluent

  DoubleType required() {
    super.required();

    return this;
  }

  DoubleType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }

  DoubleType min(double length) {
    test<double>(
      type: double,
      name: "min",
      params: {
        "min": length
      },
      check: (obj) => obj >= length,
    );

    return this;
  }

  DoubleType max(double length) {
    test<double>(
      type: double,
      name: "max",
      params: {
        "max": length
      },
      check: (obj) => obj <= length,
    );

    return this;
  }

  DoubleType lessThan(double length) {
    test<double>(
      type: double,
      name: "lessThan",
      params: {
        "lessThan": length
      },
      check: (obj) => obj < length,
    );

    return this;
  }

  DoubleType lessThanEquals(double length) {
    test<double>(
      type: double,
      name: "lessThanEquals",
      params: {
        "lessThanEquals": length
      },
      check: (obj) => obj <= length,
    );

    return this;
  }

  DoubleType greaterThan(double length) {
    test<double>(
      type: double,
      name: "greaterThan",
      params: {
        "greaterThan": length
      },
      check: (obj) => obj > length,
    );

    return this;
  }

  DoubleType greaterThanEquals(double length) {
    test<double>(
      type: double,
      name: "greaterThanEquals",
      params: {
        "greaterThanEquals": length
      },
      check: (obj) => obj >= length,
    );

    return this;
  }
}

// string

class StringType extends AbstractType<String> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'minLength': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).minLength(a[0])),
    'maxLength': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).maxLength(a[0])),
    'length': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic)
        .minLength(a[0])
        .maxLength(a[0])),
    're': MethodSpec(1, [ArgType.string_type], (t, a) => (t as dynamic).test<String>(
      type: String,
      name: "re",
      params: {"pattern": a[0]},
      check: (s) => RegExp(a[0]).hasMatch(s),
    )),
    'notEmpty': MethodSpec(0, [], (t, a) => (t as dynamic).notEmpty()),
  };

  // static methods

  static StringType fromString(String input) {
    var result = StringType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  StringType() : super(type: String) {
    baseType<String>(String);
  }

  // fluent

  StringType required() {
    super.required();

    return this;
  }

  StringType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }

  StringType notEmpty() {
    test<String>(
      type: String,
      name: "notEmpty",
      check: (s) => s.isNotEmpty,
    );

    return this;
  }

  StringType  minLength(int length) {
    test<String> (
      type: String,
      name: "minLength",
      params: {
        "minLength": length
      },
      check: (s) => s.length >= length,
    );

    return this;
  }

  StringType  maxLength(int length) {
    test<String> (
      type: String,
      name: "maxLength",
      params: {
        "maxLength": length
      },
      check: (s) => s.length <= length,
    );

    return this;
  }
}

class BoolType extends AbstractType<bool> {
  // static data

  static final Map<String, MethodSpec> methods = {
  };

  // static methods

  static BoolType fromString(String input) {
    var result = BoolType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  BoolType() : super(type: bool) {
    baseType<bool>(bool);
  }

  // override

  BoolType required() {
    super.required();

    return this;
  }

  BoolType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }
}

class ObjectType<T> extends AbstractType<T> {
  // static data

  static final Map<String, MethodSpec> methods = {
  };
  
  // instance data
  
  late TypeDescriptor typeDescriptor;

  // constructor

  ObjectType(Type type) : super(type: type) {
    baseType<T>(type);

    typeDescriptor = TypeDescriptor.forType(type);
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }

  @override
  void check(dynamic object, ValidationContext context) {
    super.check(object, context);
    
    if ( object != null) {
      var path = context.path;
      
      for (FieldDescriptor field in typeDescriptor.getFields()) {
        context.path = "$path.${field.name}";

        field.type.check(field.getter(object), context);
      }
      
      context.path = path;
    }
  }
}

class ListType<T> extends AbstractType<T> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'min': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).min(a[0])),
    'max': MethodSpec(1, [ArgType.int_type], (t, a) => (t as dynamic).max(a[0])),
  };

  // constructor

  ListType(Type type) : super(type: type) {
    this.type = type;

    test<dynamic>(
        type: type,
        name: "type",
        params: {
          "type": type
        },
        check: (dynamic object) => object is List,
        stop: true
    );
  }

  // fluent

  ListType min(int length) {
    test<List> (
      type: List,
      name: "min",
      params: {
        "min": length
      },
      check: (s) => s.length <= length,
    );

    return this;
  }

  ListType  max(int length) {
    test<List> (
      type: List,
      name: "max",
      params: {
        "max": length
      },
      check: (s) => s.length <= length,
    );

    return this;
  }


  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }
}