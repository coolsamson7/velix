import 'package:flutter_test/flutter_test.dart';

import 'package:velix/velix.dart';

void main() {
  group('StringParser', () {

    test('parse', () {
      var type = IntType.fromString("< 7 > 0");

      var code = type.code();

      print(code);
      //expect(() => type.validate(""), throwsA(isA<ValidationException>()));
    });
  });


  group('StringType', () {
    //test('passes for valid string', () {
    //  var validator = StringType().notEmpty().minLength(3);
    //  expect(() => validator.validate("hello"), returnsNormally);
    //});

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
    //test('passes for valid string', () {
    //  var validator = StringType().notEmpty().minLength(3);
    //  expect(() => validator.validate("hello"), returnsNormally);
    //});

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
    //test('passes for valid string', () {
    //  var validator = StringType().notEmpty().minLength(3);
    //  expect(() => validator.validate("hello"), returnsNormally);
    //});

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