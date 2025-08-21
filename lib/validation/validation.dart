import '../i18n/i18n.dart';
import '../reflectable/reflectable.dart';

/// @internal
typedef Check<T> = bool Function(T);

/// @internal
class Test<T> {
  final Type type;
  final String name;
  bool stop;
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

/// @internal
typedef MethodApplier<T> = void Function(AbstractType<T>, List<dynamic> args);

/// @internal
enum ArgType {
  stringType,
  intType,
  doubleType;

  dynamic parse(String value) {
    switch (this) {
      case ArgType.stringType:
        return value;
      case ArgType.intType:
        return int.parse(value);
      case ArgType.doubleType:
        return double.parse(value);
    }
  }

  String get name => toString().split('.').last;
}

/// @internal
class MethodSpec {
  // instance data

  final int argCount;
  final List<ArgType> argTypes;
  final MethodApplier<dynamic> apply;

  const MethodSpec(this.argCount, this.argTypes, this.apply);
}

/// Base class for type constraints based on a literal type.
/// [T] the literal type
class AbstractType<T> {
  // instance data

  late Type type;
  List<Test<dynamic>> tests = [];

  // constructor

  /// Create a new [AbstractType]
  /// [type] the literal type
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

        if ( test.ignore)
          buffer.write(".optional()");
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

  void baseType<V>(Type type) {
    this.type = type;

    test<dynamic>(
        type: type,
        name: "type",
        params: {
          "type": type
        },
        check: (dynamic object) => object is V,
        stop: true
    );
  }

  AbstractType<T> required() {
    var typeTest = tests[0];

    typeTest.ignore = false;

    return this;
  }

  AbstractType<T> optional()  {
    var typeTest = tests[0];

    typeTest.ignore = true;
    typeTest.stop = true;

    return this;
  }

  // public

  /// validate the passed object. In case of a type violation,  a [ValidationException] will be thrown
  /// [object] the to be validated object.
  void validate(dynamic object) {
    ValidationContext context = ValidationContext();

    check(object, context);

    if (context.hasViolations) {
      throw ValidationException(violations: context.violations);
    }
  }

  /// return [true], if the specified object is valid, else [false]
  /// [object] the to be validated object.
  bool isValid(dynamic object) {
    ValidationContext context = ValidationContext();

    check(object, context);

    return !context.hasViolations;
  }
}

/// Exception thrown in case of validation violations.
class ValidationException {
  // instance data

  List<TypeViolation> violations;

  // constructor

  /// Create a new [ValidationException]
  /// [violations] the list of violations
  ValidationException({required this.violations});

  // override

  @override
  String toString() {
    var buffer = StringBuffer();

    for ( var violation in violations)
      buffer.writeln(violation.toString());

    return buffer.toString();
  }
}

/// This class describes a single violation.
class TypeViolation {
  // instance data

  final Type type;
  final String name;
  final Map<String, dynamic> params;
  final dynamic value;
  final String path;
  final String message;

  // constructor

  /// Create a new [TypeViolation]
  /// [type] the corresponding type
  /// [name] the name of the test that failed
  /// [params] the parameters of the failed test
  /// [value] the tested value
  /// [path] the path of the current property referencing the value
  /// [message] optional message of the violation
  const TypeViolation({
     required this.type,
     required this.name,
     required this.params,
     required this.value,
     required this.path,
     required this.message});
}

/// @internal
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

/// The type specification of int types
class IntType extends AbstractType<int> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'min': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).min(a[0])),
    'max': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).max(a[0])),

    'lessThan': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).lessThan(a[0])),
    'lessThanEquals': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).lessThanEquals(a[0])),
    'greaterThan': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).greaterThan(a[0])),
    'greaterThanEquals': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).greaterThanEquals(a[0])),

    '<': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).lessThan(a[0])),
    '<=': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).lessThanEquals(a[0])),
    '>': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).greaterThan(a[0])),
    '>=': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).greaterThanEquals(a[0]))
  };

  // static methods

  static IntType fromString(String input) {
    var result = IntType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  /// Create a new [IntType]
  IntType() : super(type: int) {
    baseType<int>(int);
  }

  // fluent

  @override
  IntType required() {
    super.required();

    return this;
  }

  @override
  IntType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }

  /// allow only values >= value
  /// [value] the minimum value
  IntType min(int value) {
    test<int>(
      type: int,
      name: "min",
      params: {
        "min": value
      },
      check: (obj) => obj >= value,
    );

    return this;
  }

  /// allow only values <= value
  /// [value] the maximum value
  IntType max(int value) {
    test<int>(
      type: int,
      name: "max",
      params: {
        "max": value
      },
      check: (obj) => obj <= value,
    );

    return this;
  }

  /// allow only values < value
  /// [value] the upper limit
  IntType lessThan(int value) {
    test<int>(
      type: int,
      name: "lessThan",
      params: {
        "lessThan": value
      },
      check: (obj) => obj < value,
    );

    return this;
  }

  /// allow only values <= value
  /// [value] the upper limit
  IntType lessThanEquals(int value) {
    test<int>(
      type: int,
      name: "lessThanEquals",
      params: {
        "lessThanEquals": value
      },
      check: (obj) => obj <= value,
    );

    return this;
  }

  /// allow only values > value
  /// [value] the lower limit
  IntType greaterThan(int value) {
    test<int>(
      type: int,
      name: "greaterThan",
      params: {
        "greaterThan": value
      },
      check: (obj) => obj > value,
    );

    return this;
  }

  /// allow only values <= value
  /// [value] the upper limit
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

/// type constraint for double values
class DoubleType extends AbstractType<double> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'min': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).min(a[0])),
    'max': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).max(a[0])),

    'lessThan': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).lessThan(a[0])),
    'lessThanEquals': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).lessThanEquals(a[0])),
    'greaterThan': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).greaterThan(a[0])),
    'greaterThanEquals': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).greaterThanEquals(a[0])),

    '<': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).lessThan(a[0])),
    '<=': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).lessThanEquals(a[0])),
    '>': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).greaterThan(a[0])),
    '>=': MethodSpec(1, [ArgType.doubleType], (t, a) => (t as dynamic).greaterThanEquals(a[0])),
  };

  // static methods

  static DoubleType fromString(String input) {
    var result = DoubleType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  /// Create a new [DoubleType]
  DoubleType() : super(type: double) {
    baseType<double>(double);
  }

  // fluent

  @override
  DoubleType required() {
    super.required();

    return this;
  }

  @override
  DoubleType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }

  /// allow only values >= value
  /// [value] the minimum value
  DoubleType min(double value) {
    test<double>(
      type: double,
      name: "min",
      params: {
        "min": value
      },
      check: (obj) => obj >= value,
    );

    return this;
  }

  /// allow only values <= value
  /// [value] the maximum value
  DoubleType max(double value) {
    test<double>(
      type: double,
      name: "max",
      params: {
        "max": value
      },
      check: (obj) => obj <= value,
    );

    return this;
  }

  /// allow only values < value
  /// [value] the upper limit
  DoubleType lessThan(double value) {
    test<double>(
      type: double,
      name: "lessThan",
      params: {
        "lessThan": value
      },
      check: (obj) => obj < value,
    );

    return this;
  }

  /// allow only values <= value
  /// [value] the upper limit
  DoubleType lessThanEquals(double value) {
    test<double>(
      type: double,
      name: "lessThanEquals",
      params: {
        "lessThanEquals": value
      },
      check: (obj) => obj <= value,
    );

    return this;
  }

  /// allow only values > value
  /// [value] the lower limit
  DoubleType greaterThan(double value) {
    test<double>(
      type: double,
      name: "greaterThan",
      params: {
        "greaterThan": value
      },
      check: (obj) => obj > value,
    );

    return this;
  }

  /// allow only values <= value
  /// [value] the upper limit
  DoubleType greaterThanEquals(double value) {
    test<double>(
      type: double,
      name: "greaterThanEquals",
      params: {
        "greaterThanEquals": value
      },
      check: (obj) => obj >= value,
    );

    return this;
  }
}

// string

/// The type specification of String types
class StringType extends AbstractType<String> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'minLength': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).minLength(a[0])),
    'maxLength': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).maxLength(a[0])),
    'min-length': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).minLength(a[0])),
    'max-length': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).maxLength(a[0])),
    'length': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic)
        .minLength(a[0])
        .maxLength(a[0])),
    're': MethodSpec(1, [ArgType.stringType], (t, a) => (t as dynamic).test<String>(
      type: String,
      name: "re",
      params: {"pattern": a[0]},
      check: (s) => RegExp(a[0]).hasMatch(s),
    )),
    'notEmpty': MethodSpec(0, [], (t, a) => (t as dynamic).notEmpty()),
    'not-empty': MethodSpec(0, [], (t, a) => (t as dynamic).notEmpty()),
  };

  // static methods

  static StringType fromString(String input) {
    var result = StringType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  /// Create a new [StringType]
  StringType() : super(type: String) {
    baseType<String>(String);
  }

  // fluent

  @override
  StringType required() {
    super.required();

    return this;
  }

  @override
  StringType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }

  /// requires the value to be non empty
  StringType notEmpty() {
    test<String>(
      type: String,
      name: "notEmpty",
      check: (s) => s.isNotEmpty,
    );

    return this;
  }

  /// requires the value to hava minimum length
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

  /// requires the value to have maximum length
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

/// type specification for  [bool] values
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

  /// Create a new [BoolType]
  BoolType() : super(type: bool) {
    baseType<bool>(bool);
  }

  // override

  @override
  BoolType required() {
    super.required();

    return this;
  }

  @override
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

/// type specification for  [bool] values
class DateTimeType extends AbstractType<DateTime> {
  // static data

  static final Map<String, MethodSpec> methods = {
  };

  // static methods

  static DateTimeType fromString(String input) {
    var result = DateTimeType();

    result.parse(methods, input);

    return result;
  }

  // constructor

  /// Create a new [BoolType]
  DateTimeType() : super(type: DateTime) {
    baseType<DateTime>(DateTime);
  }

  // override

  @override
  DateTimeType required() {
    super.required();

    return this;
  }

  @override
  DateTimeType optional() {
    super.optional();

    return this;
  }

  @override
  AbstractType constraint(String input) {
    super.parse(methods, input);

    return this;
  }
}

/// Type specification for class values of a certain type.
/// [T] the corresponding type
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

/// Type specification for List types
class ListType<T> extends AbstractType<T> {
  // static data

  static final Map<String, MethodSpec> methods = {
    'min': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).min(a[0])),
    'max': MethodSpec(1, [ArgType.intType], (t, a) => (t as dynamic).max(a[0])),
  };

  // constructor

  /// Create a new [ListType]
  /// [type] the element type
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

  /// requires that the list should have a minimum length
  ListType min(int length) {
    test<List> (
      type: List,
      name: "min",
      params: {
        "min": length
      },
      check: (s) => s.length >= length,
    );

    return this;
  }

  /// requires that the list should have a maximum length
  ListType max(int length) {
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

class TypeViolationTranslationProvider extends TranslationProvider<TypeViolation> {
  // override

  @override
  String translate(instance) {
    return Translator.tr("validation.${instance.type.toString().toLowerCase()}.${instance.name}", args: instance.params.map(
          (key, value) => MapEntry(key, value.toString()),
    ));
  }
}