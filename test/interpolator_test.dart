import 'package:flutter_test/flutter_test.dart';
import 'package:velix/i18n/interpolator.dart';

void main() {
  group('i18n', () {
    test('interpolator', () {
      var interpolator = Interpolator();

      var func = interpolator.parse("hello {andi}!");

      var result = func({"andi": "andi"});

      expect(result, "hello andi!");

      // with format

      func = interpolator.parse("hello {andi}, you are {age:number} years old!");
      result = func({"andi": "andi", "age": 60});

      expect(result, "hello andi, you are 60 years old!");

      // with format args

      //TODO func = interpolator.parse("hello {andi}, you are worth {price:currency(digits:2)}!");
      //TODO result = func({"andi": "andi", "price": 100.123, "symbol": "EUR"});

      //TODO expect(result, "hello andi, you are worth EUR100.12!");

      // date

      func = interpolator.parse("today is {now:date(style: 'yMd')}!");
      result = func({"now": DateTime.now()});

      //TODO expect(true, equals(true));
    });
  });
}