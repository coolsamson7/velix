import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/databinding/form_mapper.dart';
import 'package:velix/databinding/registry.dart';
import "main.dart";
import 'main.type_registry.g.dart';

void main() {
  // initialize

  registerAllDescriptors();
  registerWidgets();

  var product = Product(name: 'product', price: Money(currency: "EU", value: 1), status: Status.available);

  testWidgets('deferred & mutable instance', (WidgetTester tester) async {
    // create mapper

    var mapper = FormMapper(instance: product, twoWay: false);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Form(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.bind<TextFormField>(
                      context: context,
                      path: 'price.currency',
                    ),
                    mapper.bind<TextFormField>(
                      context: context,
                      path: 'price.value',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final currencyFinder = find.byKey(const Key('price.currency'));
    // one-way mapper

    mapper.isDirty.addListener(() {
     dirty = mapper.isDirty.value;
    });

    // set value

    mapper.setValue(product);

    expect(dirty, equals(false));

    // change currency

    await tester.enterText(currencyFinder, 'EU1');

    expect(dirty, equals(true));

    await tester.enterText(currencyFinder, 'EU');

    expect(dirty, equals(false));

    await tester.enterText(currencyFinder, 'EU1');

    expect(dirty, equals(true));

    // commit

    var productResult = mapper.commit<Product>();

    // check text

    expect(productResult.price.currency, equals('EU1'));
  });

  testWidgets('deferred & immutable instance', (WidgetTester tester) async {
    // create mapper

   var price =  Money(currency: "EU", value: 1);

    var mapper = FormMapper(instance: price, twoWay: false);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Form(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.bind<TextFormField>(
                      context: context,
                      path: 'currency',
                    ),
                    mapper.bind<TextFormField>(
                      context: context,
                      path: 'value',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final currencyFinder = find.byKey(const Key('currency'));

    // one-way mapper

    mapper.isDirty.addListener(() {
      dirty = mapper.isDirty.value;
    });

    // set value

    mapper.setValue(price);

    expect(dirty, equals(false));

    // change currency

    await tester.enterText(currencyFinder, 'EU1');

    expect(dirty, equals(true));

    // commit

    var moneyResult = mapper.commit<Money>();

    // check text

    expect(moneyResult.currency, equals('EU1'));
  });

  testWidgets('deferred & immutable instance with partial mapping', (WidgetTester tester) async {
    // create mapper

    var price =  Money(currency: "EU", value: 1);

    var mapper = FormMapper(instance: price, twoWay: false);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Form(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.bind<TextFormField>(
                      context: context,
                      path: 'value',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final valueFinder = find.byKey(const Key('value'));

    // one-way mapper

    mapper.isDirty.addListener(() {
      dirty = mapper.isDirty.value;
    });

    // set value

    mapper.setValue(price);

    expect(dirty, equals(false));

    // change currency

    await tester.enterText(valueFinder, '2');

    expect(dirty, equals(true));

    // commit

    var moneyResult = mapper.commit<Money>();

    // check text

    expect(moneyResult.currency, equals('EU'));
    expect(moneyResult.value, equals(2));
  });


  testWidgets('two-way & immutable instance', (WidgetTester tester) async {
    // create mapper

    var price =  Money(currency: "EU", value: 1);

    var mapper = FormMapper(instance: price, twoWay: true);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Form(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.bind<TextFormField>(
                      context: context,
                      path: 'value',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final valueFinder = find.byKey(const Key('value'));

    // one-way mapper

    mapper.isDirty.addListener(() {
      dirty = mapper.isDirty.value;
    });

    // set value

    mapper.setValue(price);

    expect(dirty, equals(false));

    // change currency

    await tester.enterText(valueFinder, '2');

    expect(dirty, equals(true));

    // commit

    mapper.commit();

    expect(dirty, equals(false));

    // check text

    expect(mapper.instance.currency, equals('EU'));
    expect(mapper.instance.value, equals(2));
  });

  // TODO testWidgets('two-way & mutable instance', (WidgetTester tester) async {});
  // TODO testWidgets('two-way & immutable instance, not all fields mapped', (WidgetTester tester) async {});
}