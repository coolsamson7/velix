import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
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

      func = interpolator.parse("hello {andi}, you are worth {price:currency(name: 'EUR', decimalDigits: 2)}!");
      result = func({"andi": "andi", "price": 100.123});//, "symbol": "EUR"});

      expect(result, "hello andi, you are worth EUR100.12!");

      // with template args

      func = interpolator.parse("hello {andi}, you are worth {price:currency(name: \$symbol, decimalDigits: 2)}!");
      result = func({"andi": "andi", "price": 100.123, "symbol": "EUR"});

      expect(result, "hello andi, you are worth EUR100.12!");

      // date

      var today = DateTime.now();
      var format = DateFormat('yyyy-MM-dd');

      var str = format.format(today);

      func = interpolator.parse("today is {now:date(pattern: 'yyyy-MM-dd')}!");
      result = func({"now": DateTime.now()});

      expect(result, equals("today is $str!"));
    });
  });
}