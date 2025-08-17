// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:velix/velix.dart';
import 'main.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/mapper/json.dart';

void registerAllDescriptors() {
  type<Collections>(
    name: 'asset:velix/test/main.dart.Collections',
    params: [
      param<List<Money>>('prices', isNamed: true, isRequired: true),
    ],
    constructor: ({required List<Money> prices}) => Collections(prices: prices),
    fields: [
      field<Collections,List<Money>>('prices',
        elementType: Money,
        factoryConstructor: () => <Money>[],
        getter: (obj) => (obj as Collections).prices,
        isFinal: true,
      ),
    ]
  );

  var MoneyDescriptor = type<Money>(
    name: 'asset:velix/test/main.dart.Money',
    annotations: [
      JsonSerializable(includeNull: true),
    ],
    params: [
      param<String>('currency', isNamed: true, isRequired: true),
      param<int>('value', isNamed: true, isRequired: true),
    ],
    constructor: ({String currency = '', int value = 0}) => Money(currency: currency, value: value),
    fields: [
      field<Money,String>('currency',
        type: StringType().maxLength(7),
        annotations: [
          Json(name: "currency", includeNull: true, required: true, defaultValue: "EU", ignore: false),
        ],
        getter: (obj) => (obj as Money).currency,
        isFinal: true,
      ),
      field<Money,int>('value',
        type: IntType().greaterThan(0),
        annotations: [
          Json(includeNull: true, required: true, defaultValue: 1, ignore: false),
        ],
        getter: (obj) => (obj as Money).value,
        isFinal: true,
      ),
    ]
  );

  type<Mutable>(
    name: 'asset:velix/test/main.dart.Mutable',
    annotations: [
      JsonSerializable(includeNull: true),
    ],
    params: [
      param<String>('id', isNamed: true, isRequired: true),
      param<Money>('price', isNamed: true, isRequired: true),
      param<DateTime?>('dateTime', isNamed: true, isRequired: true),
    ],
    constructor: ({String id = '', required Money price, DateTime? dateTime}) => Mutable(id: id, price: price, dateTime: dateTime),
    fields: [
      field<Mutable,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => (obj as Mutable).id,
        setter: (obj, value) => (obj as Mutable).id = value,
      ),
      field<Mutable,Money>('price',
        getter: (obj) => (obj as Mutable).price,
        setter: (obj, value) => (obj as Mutable).price = value,
      ),
      field<Mutable,DateTime>('dateTime',
        annotations: [
          Json(name: "date-time"),
        ],
        getter: (obj) => (obj as Mutable).dateTime,
        setter: (obj, value) => (obj as Mutable).dateTime = value,
        isNullable: true
      ),
    ]
  );

  enumeration<Status>(
    name: 'asset:velix/test/main.dart.Status',
    values: Status.values
  );

  type<Product>(
    name: 'asset:velix/test/main.dart.Product',
    params: [
      param<String>('name', isNamed: true, isRequired: true),
      param<Money>('price', isNamed: true, isRequired: true),
      param<Status>('status', isNamed: true, isRequired: true),
    ],
    constructor: ({String name = '', required Money price, required Status status}) => Product(name: name, price: price, status: status),
    fields: [
      field<Product,String>('name',
        getter: (obj) => (obj as Product).name,
        isFinal: true,
      ),
      field<Product,Money>('price',
        getter: (obj) => (obj as Product).price,
        isFinal: true,
      ),
      field<Product,Status>('status',
        getter: (obj) => (obj as Product).status,
        isFinal: true,
      ),
    ]
  );

  type<Invoice>(
    name: 'asset:velix/test/main.dart.Invoice',
    params: [
      param<List<Product>>('products', isNamed: true, isRequired: true),
      param<DateTime>('date', isNamed: true, isRequired: true),
    ],
    constructor: ({required List<Product> products, required DateTime date}) => Invoice(products: products, date: date),
    fields: [
      field<Invoice,DateTime>('date',
        getter: (obj) => (obj as Invoice).date,
        isFinal: true,
      ),
      field<Invoice,List<Product>>('products',
        elementType: Product,
        factoryConstructor: () => <Product>[],
        getter: (obj) => (obj as Invoice).products,
        isFinal: true,
      ),
    ]
  );

  type<Flat>(
    name: 'asset:velix/test/main.dart.Flat',
    params: [
      param<String>('id', isNamed: true, isRequired: true),
      param<String>('priceCurrency', isNamed: true, isRequired: true),
      param<int>('priceValue', isNamed: true, isRequired: true),
    ],
    constructor: ({String id = '', String priceCurrency = '', int priceValue = 0}) => Flat(id: id, priceCurrency: priceCurrency, priceValue: priceValue),
    fields: [
      field<Flat,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => (obj as Flat).id,
        isFinal: true,
      ),
      field<Flat,String>('priceCurrency',
        getter: (obj) => (obj as Flat).priceCurrency,
        isFinal: true,
      ),
      field<Flat,int>('priceValue',
        getter: (obj) => (obj as Flat).priceValue,
        isFinal: true,
      ),
    ]
  );

  type<Immutable>(
    name: 'asset:velix/test/main.dart.Immutable',
    params: [
      param<String>('id', isNamed: true, isRequired: true),
      param<Money>('price', isNamed: true, isRequired: true),
    ],
    constructor: ({String id = '', required Money price}) => Immutable(id: id, price: price),
    fields: [
      field<Immutable,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => (obj as Immutable).id,
        isFinal: true,
      ),
      field<Immutable,Money>('price',
        getter: (obj) => (obj as Immutable).price,
        isFinal: true,
      ),
    ]
  );
}
