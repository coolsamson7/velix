// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'ui.dart';
import 'package:velix/reflectable/reflectable.dart';

void registerAllDescriptors() {
  type<Money>(
    location: 'asset:velix_ui/test/ui.dart:26:7',
    params: [
      param<String>('currency', isNamed: true, isRequired: true), 
      param<int>('value', isNamed: true, isRequired: true)
    ],
    constructor: ({String currency = '', int value = 0}) => Money(currency: currency, value: value),
    fromArrayConstructor: (List<dynamic> args) => Money(currency: args[0] as String? ?? '', value: args[1] as int? ?? 0),
    fields: [
      field<Money,String>('currency',
        type: StringType().maxLength(7),
        getter: (obj) => obj.currency,
      ), 
      field<Money,int>('value',
        type: IntType().greaterThan(0),
        getter: (obj) => obj.value,
      )
    ]
  );

  enumeration<Status>(
    name: 'asset:velix_ui/test/ui.dart.Status',
    values: Status.values
  );

  type<Product>(
    location: 'asset:velix_ui/test/ui.dart:9:7',
    params: [
      param<String>('name', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true), 
      param<Status>('status', isNamed: true, isRequired: true)
    ],
    constructor: ({String name = '', required Money price, required Status status}) => Product(name: name, price: price, status: status),
    fromArrayConstructor: (List<dynamic> args) => Product(name: args[0] as String? ?? '', price: args[1] as Money, status: args[2] as Status),
    fields: [
      field<Product,String>('name',
        getter: (obj) => obj.name,
        setter: (obj, value) => (obj as Product).name = value,
      ), 
      field<Product,Money>('price',
        getter: (obj) => obj.price,
        setter: (obj, value) => (obj as Product).price = value,
      ), 
      field<Product,Status>('status',
        getter: (obj) => obj.status,
        setter: (obj, value) => (obj as Product).status = value,
      )
    ]
  );

  type<Invoice>(
    location: 'asset:velix_ui/test/ui.dart:18:7',
    params: [
      param<List<Product>>('products', isNamed: true, isRequired: true), 
      param<DateTime>('date', isNamed: true, isRequired: true)
    ],
    constructor: ({required List<Product> products, required DateTime date}) => Invoice(products: products, date: date),
    fromArrayConstructor: (List<dynamic> args) => Invoice(products: args[0] as List<Product>, date: args[1] as DateTime),
    fields: [
      field<Invoice,DateTime>('date',
        getter: (obj) => obj.date,
      ), 
      field<Invoice,List<Product>>('products',
        elementType: Product,
        factoryConstructor: () => <Product>[],
        getter: (obj) => obj.products,
      )
    ]
  );

  type<ImmutableProduct>(
    location: 'asset:velix_ui/test/ui.dart:39:7',
    params: [
      param<String>('name', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true), 
      param<Status>('status', isNamed: true, isRequired: true)
    ],
    constructor: ({String name = '', required Money price, required Status status}) => ImmutableProduct(name: name, price: price, status: status),
    fromArrayConstructor: (List<dynamic> args) => ImmutableProduct(name: args[0] as String? ?? '', price: args[1] as Money, status: args[2] as Status),
    fields: [
      field<ImmutableProduct,String>('name',
        getter: (obj) => obj.name,
      ), 
      field<ImmutableProduct,Money>('price',
        getter: (obj) => obj.price,
      ), 
      field<ImmutableProduct,Status>('status',
        getter: (obj) => obj.status,
      )
    ]
  );

  type<ImmutableRoot>(
    location: 'asset:velix_ui/test/ui.dart:48:7',
    params: [
      param<ImmutableProduct>('product', isNamed: true, isRequired: true)
    ],
    constructor: ({required ImmutableProduct product}) => ImmutableRoot(product: product),
    fromArrayConstructor: (List<dynamic> args) => ImmutableRoot(product: args[0] as ImmutableProduct),
    fields: [
      field<ImmutableRoot,ImmutableProduct>('product',
        getter: (obj) => obj.product,
      )
    ]
  );

  TypeDescriptor.verify();
}
