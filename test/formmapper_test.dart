import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/databinding/form_mapper.dart';
import 'package:velix/databinding/registry.dart';
import "main.dart";
import 'main.type_registry.g.dart';

void main() {
  registerAllDescriptors();
  registerWidgets();

  var product = Product(name: 'product', price: Money(currency: "EU", value: 1), status: Status.available);

  testWidgets('Replace text in a TextField', (WidgetTester tester) async {
    // create mapper

    var mapper = FormMapper(instance: product, twoWay: false);

    TextFormField currencyField;
    TextFormField valueField;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Form(
                key: mapper.getKey(),
                child: Column(
                  children: [
                    currencyField = mapper.bind<TextFormField>(
                      context: context,
                      path: 'price.currency',
                    ),
                    valueField = mapper.bind<TextFormField>(
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
    final valueFinder = find.byKey(const Key('price.value'));

    // one-way mapper

    mapper.isDirty.addListener(() {
     print( mapper.isDirty.value);
    });

    // set value

    mapper.setValue(product);

    // change currency

    await tester.enterText(currencyFinder, 'EU1');

    // commit

    var productResult = mapper.commit<Product>();

    print(productResult);

    // check text

    expect(productResult.price.currency, equals('EU1'));
  });
}