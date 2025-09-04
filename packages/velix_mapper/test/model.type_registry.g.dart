// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'model.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';

void registerAllDescriptors() {
  type<Money>(
    location: 'asset:velix_mapper/test/model.dart:58:7',
    annotations: [
      JsonSerializable(includeNull: true)
    ],
    params: [
      param<String>('currency', isNamed: true, isRequired: true), 
      param<int>('value', isNamed: true, isRequired: true)
    ],
    constructor: ({String currency = '', int value = 0}) => Money(currency: currency, value: value),
    fromArrayConstructor: (List<dynamic> args) => Money(currency: args[0] as String? ?? '', value: args[1] as int? ?? 0),
    fields: [
      field<Money,String>('currency',
        type: StringType().maxLength(7),
        annotations: [
          Json(name: "currency", includeNull: true, required: true, defaultValue: "EU", ignore: false)
        ],
        getter: (obj) => obj.currency,
      ), 
      field<Money,int>('value',
        type: IntType().greaterThan(0),
        annotations: [
          Json(includeNull: true, required: true, defaultValue: 1, ignore: false)
        ],
        getter: (obj) => obj.value,
      )
    ]
  );

  type<Mutable>(
    location: 'asset:velix_mapper/test/model.dart:7:7',
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true), 
      param<DateTime>('dateTime', isNamed: true, isRequired: true)
    ],
    constructor: ({String id = '', required Money price, required DateTime dateTime}) => Mutable(id: id, price: price, dateTime: dateTime),
    fromArrayConstructor: (List<dynamic> args) => Mutable(id: args[0] as String? ?? '', price: args[1] as Money, dateTime: args[2] as DateTime),
    fields: [
      field<Mutable,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => obj.id,
        setter: (obj, value) => (obj as Mutable).id = value,
      ), 
      field<Mutable,Money>('price',
        getter: (obj) => obj.price,
        setter: (obj, value) => (obj as Mutable).price = value,
      ), 
      field<Mutable,DateTime>('dateTime',
        type: DateTimeType().optional(),
        getter: (obj) => obj.dateTime,
        setter: (obj, value) => (obj as Mutable).dateTime = value,
        isNullable: true
      )
    ]
  );

  type<Collections>(
    location: 'asset:velix_mapper/test/model.dart:24:7',
    params: [
      param<List<Money>>('prices', isNamed: true, isRequired: true)
    ],
    constructor: ({required List<Money> prices}) => Collections(prices: prices),
    fromArrayConstructor: (List<dynamic> args) => Collections(prices: args[0] as List<Money>),
    fields: [
      field<Collections,List<Money>>('prices',
        elementType: Money,
        factoryConstructor: () => <Money>[],
        getter: (obj) => obj.prices,
      )
    ]
  );

  enumeration<Status>(
    name: 'asset:velix_mapper/test/model.dart.Status',
    values: Status.values
  );

  type<Product>(
    location: 'asset:velix_mapper/test/model.dart:40:7',
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
    location: 'asset:velix_mapper/test/model.dart:49:7',
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

  var BaseDescriptor = type<Base>(
    location: 'asset:velix_mapper/test/model.dart:72:7',
    params: [
      param<String>('name', isRequired: true)
    ],
    constructor: ({String name = ''}) => Base(name),
    fromArrayConstructor: (List<dynamic> args) => Base(args[0] as String),
    fields: [
      field<Base,String>('name',
        getter: (obj) => obj.name,
      )
    ]
  );

  type<Derived>(
    location: 'asset:velix_mapper/test/model.dart:79:7',
    superClass: BaseDescriptor,
    params: [
      param<String>('name', isRequired: true), 
      param<int>('number', isNamed: true, isRequired: true)
    ],
    constructor: ({String name = '', int number = 0}) => Derived(name, number: number),
    fromArrayConstructor: (List<dynamic> args) => Derived(args[0] as String, number: args[1] as int? ?? 0),
    fields: [
      field<Derived,int>('number',
        getter: (obj) => obj.number,
      )
    ]
  );

  type<Types>(
    location: 'asset:velix_mapper/test/model.dart:86:7',
    params: [
      param<int>('int_var', isNamed: true, isRequired: true), 
      param<double>('double_var', isNamed: true, isRequired: true), 
      param<bool>('bool_var', isNamed: true, isRequired: true), 
      param<String>('string_var', isNamed: true, isRequired: true)
    ],
    constructor: ({int int_var = 0, double double_var = 0.0, bool bool_var = false, String string_var = ''}) => Types(int_var: int_var, double_var: double_var, bool_var: bool_var, string_var: string_var),
    fromArrayConstructor: (List<dynamic> args) => Types(int_var: args[0] as int? ?? 0, double_var: args[1] as double? ?? 0.0, bool_var: args[2] as bool? ?? false, string_var: args[3] as String? ?? ''),
    fields: [
      field<Types,int>('int_var',
        getter: (obj) => obj.int_var,
      ), 
      field<Types,double>('double_var',
        getter: (obj) => obj.double_var,
      ), 
      field<Types,bool>('bool_var',
        getter: (obj) => obj.bool_var,
      ), 
      field<Types,String>('string_var',
        getter: (obj) => obj.string_var,
      )
    ]
  );

  type<Immutable>(
    location: 'asset:velix_mapper/test/model.dart:97:7',
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<Money>('price', isNamed: true, isRequired: true)
    ],
    constructor: ({String id = '', required Money price}) => Immutable(id: id, price: price),
    fromArrayConstructor: (List<dynamic> args) => Immutable(id: args[0] as String? ?? '', price: args[1] as Money),
    fields: [
      field<Immutable,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => obj.id,
      ), 
      field<Immutable,Money>('price',
        getter: (obj) => obj.price,
      )
    ]
  );
}
