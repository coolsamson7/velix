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
    fromMapConstructor: (Map<String,dynamic> args) => Collections(prices: args['prices'] as List<Money>),
    fromArrayConstructor: (List<dynamic> args) => Collections(prices: args[0] as List<Money>),
    fields: [
      field<Collections,List<Money>>('prices',
        elementType: Money,
        factoryConstructor: () => <Money>[],
        getter: (obj) => (obj as Collections).prices,
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
    fromMapConstructor: (Map<String,dynamic> args) => Money(currency: args['currency'] as String? ?? '', value: args['value'] as int? ?? 0),
    fromArrayConstructor: (List<dynamic> args) => Money(currency: args[0] as String? ?? '', value: args[1] as int? ?? 0),
    fields: [
      field<Money,String>('currency',
        type: StringType().maxLength(7),
        annotations: [
          Json(name: "currency", includeNull: true, required: true, defaultValue: "EU", ignore: false)
        ],
        getter: (obj) => (obj as Money).currency,
      ), 
      field<Money,int>('value',
        type: IntType().greaterThan(0),
        annotations: [
          Json(includeNull: true, required: true, defaultValue: 1, ignore: false)
        ],
        getter: (obj) => (obj as Money).value,
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
    fromMapConstructor: (Map<String,dynamic> args) => ImmutableProduct(name: args['name'] as String ?? '', price: args['price'] as Money, status: args['status'] as Status),
    fromArrayConstructor: (List<dynamic> args) => ImmutableProduct(name: args[0] as String ?? '', price: args[1] as Money, status: args[2] as Status),
    fields: [
      field<ImmutableProduct,String>('name',
        getter: (obj) => (obj as ImmutableProduct).name,
      ), 
      field<ImmutableProduct,Money>('price',
        getter: (obj) => (obj as ImmutableProduct).price,
      ), 
      field<ImmutableProduct,Status>('status',
        getter: (obj) => (obj as ImmutableProduct).status,
      )
    ]
  );

  type<ImmutableRoot>(
    name: 'asset:velix/test/main.dart.ImmutableRoot',
    params: [
      param<ImmutableProduct>('product', isNamed: true, isRequired: true)
    ],
    constructor: ({required ImmutableProduct product}) => ImmutableRoot(product: product),
    fromMapConstructor: (Map<String,dynamic> args) => ImmutableRoot(product: args['product'] as ImmutableProduct),
    fromArrayConstructor: (List<dynamic> args) => ImmutableRoot(product: args[0] as ImmutableProduct),
    fields: [
      field<ImmutableRoot,ImmutableProduct>('product',
        getter: (obj) => (obj as ImmutableRoot).product,
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
    fromMapConstructor: (Map<String,dynamic> args) => Product(name: args['name'] as String ?? '', price: args['price'] as Money, status: args['status'] as Status),
    fromArrayConstructor: (List<dynamic> args) => Product(name: args[0] as String ?? '', price: args[1] as Money, status: args[2] as Status),
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
    fromMapConstructor: (Map<String,dynamic> args) => MutableRoot(product: args['product'] as Product),
    fromArrayConstructor: (List<dynamic> args) => MutableRoot(product: args[0] as Product),
    fields: [
      field<MutableRoot,Product>('product',
        getter: (obj) => (obj as MutableRoot).product,
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
    fromMapConstructor: (Map<String,dynamic> args) => Mutable(id: args['id'] as String ?? '', price: args['price'] as Money, dateTime: args['dateTime'] as DateTime),
    fromArrayConstructor: (List<dynamic> args) => Mutable(id: args[0] as String ?? '', price: args[1] as Money, dateTime: args[2] as DateTime),
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
    fromMapConstructor: (Map<String,dynamic> args) => Base(args['name'] as String),
    fromArrayConstructor: (List<dynamic> args) => Base(args[0] as String),
    fields: [
      field<Base,String>('name',
        getter: (obj) => (obj as Base).name,
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
    fromMapConstructor: (Map<String,dynamic> args) => Derived(args['name'] as String, number: args['number'] as int ?? 0),
    fromArrayConstructor: (List<dynamic> args) => Derived(args[0] as String, number: args[1] as int ?? 0),
    fields: [
      field<Derived,int>('number',
        getter: (obj) => (obj as Derived).number,
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
    fromMapConstructor: (Map<String,dynamic> args) => Types(int_var: args['int_var'] as int ?? 0, double_var: args['double_var'] as double ?? 0.0, bool_var: args['bool_var'] as bool ?? false, string_var: args['string_var'] as String ?? ''),
    fromArrayConstructor: (List<dynamic> args) => Types(int_var: args[0] as int ?? 0, double_var: args[1] as double ?? 0.0, bool_var: args[2] as bool ?? false, string_var: args[3] as String ?? ''),
    fields: [
      field<Types,int>('int_var',
        getter: (obj) => (obj as Types).int_var,
      ), 
      field<Types,double>('double_var',
        getter: (obj) => (obj as Types).double_var,
      ), 
      field<Types,bool>('bool_var',
        getter: (obj) => (obj as Types).bool_var,
      ), 
      field<Types,String>('string_var',
        getter: (obj) => (obj as Types).string_var,
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
    fromMapConstructor: (Map<String,dynamic> args) => Invoice(products: args['products'] as List<Product>, date: args['date'] as DateTime),
    fromArrayConstructor: (List<dynamic> args) => Invoice(products: args[0] as List<Product>, date: args[1] as DateTime),
    fields: [
      field<Invoice,DateTime>('date',
        getter: (obj) => (obj as Invoice).date,
      ), 
      field<Invoice,List<Product>>('products',
        elementType: Product,
        factoryConstructor: () => <Product>[],
        getter: (obj) => (obj as Invoice).products,
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
    fromMapConstructor: (Map<String,dynamic> args) => Flat(id: args['id'] as String ?? '', priceCurrency: args['priceCurrency'] as String ?? '', priceValue: args['priceValue'] as int ?? 0),
    fromArrayConstructor: (List<dynamic> args) => Flat(id: args[0] as String ?? '', priceCurrency: args[1] as String ?? '', priceValue: args[2] as int ?? 0),
    fields: [
      field<Flat,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => (obj as Flat).id,
      ), 
      field<Flat,String>('priceCurrency',
        getter: (obj) => (obj as Flat).priceCurrency,
      ), 
      field<Flat,int>('priceValue',
        getter: (obj) => (obj as Flat).priceValue,
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
    fromMapConstructor: (Map<String,dynamic> args) => Immutable(id: args['id'] as String ?? '', price: args['price'] as Money),
    fromArrayConstructor: (List<dynamic> args) => Immutable(id: args[0] as String ?? '', price: args[1] as Money),
    fields: [
      field<Immutable,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => (obj as Immutable).id,
      ), 
      field<Immutable,Money>('price',
        getter: (obj) => (obj as Immutable).price,
      )
    ]
  );
}
