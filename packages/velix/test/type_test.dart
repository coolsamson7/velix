
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';


void main() {
  group('StringParser', () {

    test('parse', () {
      var type = IntType().constraint("< 7 > 0");

      var code = type.code();

      expect(code, equals("IntType().lessThan(7).greaterThan(0)"));
    });
  });


  group('StringType', () {
    test('test null', () {
      var type = StringType().optional();

      expect(type.isValid(null), equals(true));
      expect(type.isValid(1), equals(false));

      type = StringType().required();

      expect(type.isValid(null), equals(false));
      expect(type.isValid(1), equals(false));
    });

    test('fails for empty string', () {
      var type = StringType().notEmpty();
      expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });

    test('fails for short string', () {
      var type = StringType().minLength(5);
      expect(() => type.validate("hey"), throwsA(isA<ValidationException>()));
    });
  });

  group('IntType', () {
    test('<', () {
      var type = IntType().lessThan(1).lessThan(2);
      expect(
            () => type.validate(10),
        throwsA(
          predicate(
                (e) {
              expect(e, isA<ValidationException>());
              expect((e as ValidationException).violations.length, 2);
              //expect(e.violations.first, contains("lessThan"));
              return true;
            },
            'ValidationException with correct violations',
          ),
        ),
      );
    });
  });

  group('DoubleType', () {

    test('<', () {
      var type = DoubleType().lessThan(1.0).lessThan(2.0);
      expect(
            () => type.validate(10.0),
        throwsA(
          predicate(
                (e) {
              expect(e, isA<ValidationException>());
              expect((e as ValidationException).violations.length, 2);
              //expect(e.violations.first, contains("lessThan"));
              return true;
            },
            'ValidationException with correct violations',
          ),
        ),
      );
    });
  });
}