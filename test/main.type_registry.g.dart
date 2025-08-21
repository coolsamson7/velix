// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'main.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/mapper/json.dart';

void registerAllDescriptors() {
  type<Collections>(
    name: 'asset:velix/test/main.dart.Collections',
    params: [
      param<List<Money>>('prices', isNamed: true, isRequired: true)
    ],
    constructor: ({required List<Money> prices}) => Collections(prices: prices),
    fields: [
      field<Collections,List<Money>>('prices',
        elementType: Money,
        factoryConstructor: () => <Money>[],
        getter: (obj) => (obj as Collections).prices,
        isFinal: true,
      )
    ]
  );

  type<Money>(
    name: 'asset:velix/test/main.dart.Money',
    annotations: [
      JsonSerializable(includeNull: true)
    ],
    params: [
      param<String>('currency', isNamed: true, isRequired: true), 
      param<int>('value', isNamed: true, isRequired: true)
    ],
    constructor: ({String currency = '', int value = 0}) => Money(currency: currency, value: value),
    fields: [
      field<Money,String>('currency',
        type: StringType().maxLength(7),
        annotations: [
          Json(name: "currency", includeNull: true, required: true, defaultValue: "EU", ignore: false)
        ],
        getter: (obj) => (obj as Money).currency,
        isFinal: true,
      ), 
      field<Money,int>('value',
        type: IntType().greaterThan(0),
        annotations: [
          Json(includeNull: true, required: true, defaultValue: 1, ignore: false)
        ],
        getter: (obj) => (obj as Money).value,
        isFinal: true,
      )
    ]
  );

  enumeration<Status>(
    name: 'asset:velix/test/main.dart.Status',
    values: Status.values
  );

  type<ImmutableProduct>(
    name: 'asset:velix/test/main.dart.ImmutableProduct',
    params: [
      param<String>('name', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true), 
      param<Status>('status', isNamed: true, isRequired: true)
    ],
    constructor: ({String name = '', required Money price, required Status status}) => ImmutableProduct(name: name, price: price, status: status),
    fields: [
      field<ImmutableProduct,String>('name',
        getter: (obj) => (obj as ImmutableProduct).name,
        isFinal: true,
      ), 
      field<ImmutableProduct,Money>('price',
        getter: (obj) => (obj as ImmutableProduct).price,
        isFinal: true,
      ), 
      field<ImmutableProduct,Status>('status',
        getter: (obj) => (obj as ImmutableProduct).status,
        isFinal: true,
      )
    ]
  );

  type<ImmutableRoot>(
    name: 'asset:velix/test/main.dart.ImmutableRoot',
    params: [
      param<ImmutableProduct>('product', isNamed: true, isRequired: true)
    ],
    constructor: ({required ImmutableProduct product}) => ImmutableRoot(product: product),
    fields: [
      field<ImmutableRoot,ImmutableProduct>('product',
        getter: (obj) => (obj as ImmutableRoot).product,
        isFinal: true,
      )
    ]
  );

  type<Product>(
    name: 'asset:velix/test/main.dart.Product',
    params: [
      param<String>('name', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true), 
      param<Status>('status', isNamed: true, isRequired: true)
    ],
    constructor: ({String name = '', required Money price, required Status status}) => Product(name: name, price: price, status: status),
    fields: [
      field<Product,String>('name',
        getter: (obj) => (obj as Product).name,
        setter: (obj, value) => (obj as Product).name = value,
      ), 
      field<Product,Money>('price',
        getter: (obj) => (obj as Product).price,
        setter: (obj, value) => (obj as Product).price = value,
      ), 
      field<Product,Status>('status',
        getter: (obj) => (obj as Product).status,
        setter: (obj, value) => (obj as Product).status = value,
      )
    ]
  );

  type<MutableRoot>(
    name: 'asset:velix/test/main.dart.MutableRoot',
    params: [
      param<Product>('product', isNamed: true, isRequired: true)
    ],
    constructor: ({required Product product}) => MutableRoot(product: product),
    fields: [
      field<MutableRoot,Product>('product',
        getter: (obj) => (obj as MutableRoot).product,
        isFinal: true,
      )
    ]
  );

  type<Mutable>(
    name: 'asset:velix/test/main.dart.Mutable',
    annotations: [
      JsonSerializable(includeNull: true)
    ],
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true), 
      param<DateTime>('dateTime', isNamed: true, isRequired: true)
    ],
    constructor: ({String id = '', required Money price, required DateTime dateTime}) => Mutable(id: id, price: price, dateTime: dateTime),
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
        type: DateTimeType().optional(),
        annotations: [
          Json(name: "date-time")
        ],
        getter: (obj) => (obj as Mutable).dateTime,
        setter: (obj, value) => (obj as Mutable).dateTime = value,
        isNullable: true
      )
    ]
  );

  var BaseDescriptor = type<Base>(
    name: 'asset:velix/test/main.dart.Base',
    params: [
      param<String>('name', isRequired: true)
    ],
    constructor: ({String name = ''}) => Base(name),
    fields: [
      field<Base,String>('name',
        getter: (obj) => (obj as Base).name,
        isFinal: true,
      )
    ]
  );

  type<Derived>(
    name: 'asset:velix/test/main.dart.Derived',
    superClass: BaseDescriptor,
    params: [
      param<String>('name', isRequired: true), 
      param<int>('number', isNamed: true, isRequired: true)
    ],
    constructor: ({String name = '', int number = 0}) => Derived(name, number: number),
    fields: [
      field<Derived,int>('number',
        getter: (obj) => (obj as Derived).number,
        isFinal: true,
      )
    ]
  );

  type<Types>(
    name: 'asset:velix/test/main.dart.Types',
    params: [
      param<int>('int_var', isNamed: true, isRequired: true), 
      param<double>('double_var', isNamed: true, isRequired: true), 
      param<bool>('bool_var', isNamed: true, isRequired: true), 
      param<String>('string_var', isNamed: true, isRequired: true)
    ],
    constructor: ({int int_var = 0, double double_var = 0.0, bool bool_var = false, String string_var = ''}) => Types(int_var: int_var, double_var: double_var, bool_var: bool_var, string_var: string_var),
    fields: [
      field<Types,int>('int_var',
        getter: (obj) => (obj as Types).int_var,
        isFinal: true,
      ), 
      field<Types,double>('double_var',
        getter: (obj) => (obj as Types).double_var,
        isFinal: true,
      ), 
      field<Types,bool>('bool_var',
        getter: (obj) => (obj as Types).bool_var,
        isFinal: true,
      ), 
      field<Types,String>('string_var',
        getter: (obj) => (obj as Types).string_var,
        isFinal: true,
      )
    ]
  );

  type<Invoice>(
    name: 'asset:velix/test/main.dart.Invoice',
    params: [
      param<List<Product>>('products', isNamed: true, isRequired: true), 
      param<DateTime>('date', isNamed: true, isRequired: true)
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
      )
    ]
  );

  type<Flat>(
    name: 'asset:velix/test/main.dart.Flat',
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<String>('priceCurrency', isNamed: true, isRequired: true), 
      param<int>('priceValue', isNamed: true, isRequired: true)
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
      )
    ]
  );

  type<Immutable>(
    name: 'asset:velix/test/main.dart.Immutable',
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true)
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
      )
    ]
  );
}
