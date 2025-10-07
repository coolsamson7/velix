import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/velix.dart';

import 'package:velix_ui/velix_ui.dart';

import 'main.types.g.dart';

@Dataclass()
enum Status {
  available
}

@Dataclass()
class Product {
  String name;
  Money price;
  Status status;

  Product({required this.name, required this.price, required this.status});
}

@Dataclass()
class Invoice {
  final DateTime date;
  final List<Product> products;

  Invoice({required this.products, required this.date});
}

@Dataclass()
class Money {
  // instance data

  @Attribute(type: "maxLength 7")
  final String currency;
  @Attribute(type: "greaterThan 0")
  final int value;

  const Money({required this.currency, required this.value});
}


@Dataclass()
class ImmutableProduct {
  final String name;
  final Money price;
  final Status status;

  ImmutableProduct({required this.name, required this.price, required this.status});
}

@Dataclass()
class ImmutableRoot {
  // instance data

  @Attribute()
  final ImmutableProduct product;

  const ImmutableRoot({required this.product});
}


class TypeViolationTranslationProvider extends TranslationProvider<TypeViolation> {
  // override

  @override
  String translate(instance) {
    return "";
  }
}


void main() {
  // initialize

  registerAllDescriptors();
  ValuedWidget.platform = TargetPlatform.iOS;

  TypeViolationTranslationProvider();

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
              return SmartForm(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.text(
                      context: context,
                      path: 'price.currency',
                    ),
                    mapper.text(
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

    mapper.addListener((event) {
      dirty = event.isDirty;
    }, emitOnDirty: true);

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

    var price = Money(currency: "EU", value: 1);
    var root = ImmutableRoot(product: ImmutableProduct(name: "name", price: price, status: Status.available));

    var mapper = FormMapper(instance: root, twoWay: false);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SmartForm(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.text(
                      context: context,
                      path: 'product.price.currency',
                    ),
                    mapper.text(
                      context: context,
                      path: 'product.price.value',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final currencyFinder = find.byKey(const Key('product.price.currency'));

    // one-way mapper

    mapper.addListener((event) {
      dirty = event.isDirty;
    }, emitOnDirty: true);

    // set value

    mapper.setValue(root);

    expect(dirty, equals(false));

    // change currency

    await tester.enterText(currencyFinder, 'EU1');

    expect(dirty, equals(true));

    // commit

    var rootResult = mapper.commit<ImmutableRoot>();

    // check text

    expect(rootResult.product.price.currency, equals('EU1'));
  });

  testWidgets('rollback', (WidgetTester tester) async {
    // create mapper

    var price = Money(currency: "EU", value: 1);
    var mapper = FormMapper(instance: price, twoWay: false);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SmartForm(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.text(
                      context: context,
                      path: 'currency',
                    )
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

    mapper.addListener((event) {
      dirty = event.isDirty;
    }, emitOnDirty: true);

    // set value

    mapper.setValue(price);

    await tester.enterText(currencyFinder, 'EU1');

    mapper.rollback();
    await tester.pump();

    expect(dirty, equals(false));
  });

  testWidgets('validation', (WidgetTester tester) async {
    // create mapper

    var price = Money(currency: "EU", value: -1);
    var mapper = FormMapper(instance: price, twoWay: false);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SmartForm(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.text(
                      context: context,
                      path: 'value',
                    )
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

    mapper.addListener((event) {
      dirty = event.isDirty;
    }, emitOnDirty: true);

    // set value

    mapper.setValue(price);

    expect(mapper.validate(), equals(false));

    await tester.enterText(valueFinder, '1');
    await tester.pump(); // let the widget rebuild

    expect(dirty, equals(true));

    expect(mapper.validate(), equals(true));

    var result = mapper.commit<Money>();

    expect(result.value, equals(1));
  });

  testWidgets('deferred & immutable instance with partial mapping', (WidgetTester tester) async {
    // create mapper

    var price = Money(currency: "EU", value: 1);

    var mapper = FormMapper(instance: price, twoWay: false);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SmartForm(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.text(
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

    mapper.addListener((event) {
      dirty = event.isDirty;
    }, emitOnDirty: true);

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
              return SmartForm(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.text(
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

    mapper.addListener((event) {
      dirty = event.isDirty;
    }, emitOnDirty: true);

    // set value

    mapper.setValue(price);

    expect(dirty, equals(false));

    // change currency

    await tester.enterText(valueFinder, '2');

    expect(dirty, equals(true));

    // commit

    mapper.commit();
    await tester.pump();

    expect(dirty, equals(false));

    // check text

    expect(mapper.instance.currency, equals('EU'));
    expect(mapper.instance.value, equals(2));
  });

  testWidgets('two-way & mutable instance', (WidgetTester tester) async {
    // create mapper

    var price =  Money(currency: "EU", value: 1);
    var product = Product(name: "name", price: price, status: Status.available);
    var mapper = FormMapper(instance: product, twoWay: true);

    bool dirty = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SmartForm(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    mapper.text(
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

    final valueFinder = find.byKey(const Key('price.value'));

    // one-way mapper

    mapper.addListener((event) {
      dirty = event.isDirty;
    }, emitOnDirty: true);

    // set value

    mapper.setValue(product);

    expect(dirty, equals(false));

    // change currency

    await tester.enterText(valueFinder, '2');

    expect(dirty, equals(true));

    // commit

    mapper.commit();
    await tester.pump();

    expect(dirty, equals(false));

    // check text

    expect(product.price.currency, equals('EU'));
    expect(product.price.value, equals(2));
  });
}