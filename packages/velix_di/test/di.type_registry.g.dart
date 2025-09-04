// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'package:velix_di/velix_di.dart';
import 'di.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix/reflectable/reflectable.dart';


void registerAllDescriptors() {
  type<TestModule>(
    location: 'asset:velix_di/test/di.dart:5:7',
    annotations: [
      Module()
    ],
    constructor: () => TestModule(),
    fromArrayConstructor: (List<dynamic> args) => TestModule(),
    methods: [
      method<TestModule,ConfigurationManager>('createConfigurationManager',
        annotations: [
          Create()
        ],
        invoker: (List<dynamic> args)=> (args[0] as TestModule).createConfigurationManager()
      ), 
      method<TestModule,ConfigurationValues>('createConfigurationValues',
        annotations: [
          Create()
        ],
        invoker: (List<dynamic> args)=> (args[0] as TestModule).createConfigurationValues()
      )
    ],
  );

  type<Bar>(
    location: 'asset:velix_di/test/di.dart:23:7',
    annotations: [
      Injectable(scope: "singleton", eager: true)
    ],
    constructor: () => Bar(),
    fromArrayConstructor: (List<dynamic> args) => Bar(),
  );

  type<Baz>(
    location: 'asset:velix_di/test/di.dart:28:7',
    annotations: [
      Injectable(factory: false)
    ],
    constructor: () => Baz(),
    fromArrayConstructor: (List<dynamic> args) => Baz(),
  );

  type<Foo>(
    location: 'asset:velix_di/test/di.dart:33:7',
    annotations: [
      Injectable(scope: "environment")
    ],
    params: [
      param<Bar>('bar', isNamed: true, isRequired: true)
    ],
    constructor: ({required Bar bar}) => Foo(bar: bar),
    fromArrayConstructor: (List<dynamic> args) => Foo(bar: args[0] as Bar),
  );

  type<Factory>(
    location: 'asset:velix_di/test/di.dart:42:7',
    annotations: [
      Injectable(scope: "singleton", eager: true)
    ],
    constructor: () => Factory(),
    fromArrayConstructor: (List<dynamic> args) => Factory(),
    methods: [
      method<Factory,void>('onInit',
        annotations: [
          OnInit()
        ],
        parameters: [
          param<Environment>('environment', isRequired: true)
        ],
        invoker: (List<dynamic> args)=> (args[0] as Factory).onInit(args[1])
      ), 
      method<Factory,void>('onDestroy',
        annotations: [
          OnDestroy()
        ],
        invoker: (List<dynamic> args)=> (args[0] as Factory).onDestroy()
      ), 
      method<Factory,void>('setFoo',
        annotations: [
          Inject()
        ],
        parameters: [
          param<Foo>('foo', isRequired: true), 
          param<int>('value', isRequired: true,
                    annotations: [
            Value("foo.bar", defaultValue: 1)
          ],
)
        ],
        invoker: (List<dynamic> args)=> (args[0] as Factory).setFoo(args[1], args[2])
      ), 
      method<Factory,Baz>('createBaz',
        annotations: [
          Create()
        ],
        parameters: [
          param<Bar>('bar', isRequired: true)
        ],
        invoker: (List<dynamic> args)=> (args[0] as Factory).createBaz(args[1])
      )
    ],
  );

  type<Collections>(
    location: 'asset:velix_di/test/di.dart:68:7',
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

  type<Money>(
    location: 'asset:velix_di/test/di.dart:98:7',
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
    name: 'asset:velix_di/test/di.dart.Status',
    values: Status.values
  );

  type<ImmutableProduct>(
    location: 'asset:velix_di/test/di.dart:208:7',
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
    location: 'asset:velix_di/test/di.dart:78:7',
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

  type<Product>(
    location: 'asset:velix_di/test/di.dart:217:7',
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

  type<MutableRoot>(
    location: 'asset:velix_di/test/di.dart:88:7',
    params: [
      param<Product>('product', isNamed: true, isRequired: true)
    ],
    constructor: ({required Product product}) => MutableRoot(product: product),
    fromArrayConstructor: (List<dynamic> args) => MutableRoot(product: args[0] as Product),
    fields: [
      field<MutableRoot,Product>('product',
        getter: (obj) => obj.product,
      )
    ]
  );

  type<Mutable>(
    location: 'asset:velix_di/test/di.dart:110:7',
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

  var BaseDescriptor = type<Base>(
    location: 'asset:velix_di/test/di.dart:126:7',
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
    location: 'asset:velix_di/test/di.dart:133:7',
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

  var ConditionalBaseDescriptor = type<ConditionalBase>(
    location: 'asset:velix_di/test/di.dart:140:16',
    annotations: [
      Injectable()
    ],
    isAbstract: true,
    methods: [
      method<ConditionalBase,void>('initBase',
        annotations: [
          OnInit()
        ],
        invoker: (List<dynamic> args)=> (args[0] as ConditionalBase).initBase()
      ), 
      method<ConditionalBase,void>('destroyBase',
        annotations: [
          OnDestroy()
        ],
        invoker: (List<dynamic> args)=> (args[0] as ConditionalBase).destroyBase()
      )
    ],
  );

  type<ConditionalProd>(
    location: 'asset:velix_di/test/di.dart:156:7',
    superClass: ConditionalBaseDescriptor,
    annotations: [
      Injectable(scope: "request"),
      Conditional(requires: feature("prod"))
    ],
    constructor: () => ConditionalProd(),
    fromArrayConstructor: (List<dynamic> args) => ConditionalProd(),
    methods: [
      method<ConditionalProd,void>('initProd',
        annotations: [
          OnInit()
        ],
        invoker: (List<dynamic> args)=> (args[0] as ConditionalProd).initProd()
      ), 
      method<ConditionalProd,void>('destroyProd',
        annotations: [
          OnDestroy()
        ],
        invoker: (List<dynamic> args)=> (args[0] as ConditionalProd).destroyProd()
      ), 
      method<ConditionalProd,void>('runProd',
        annotations: [
          OnRunning()
        ],
        invoker: (List<dynamic> args)=> (args[0] as ConditionalProd).runProd()
      )
    ],
  );

  type<ConditionalDev>(
    location: 'asset:velix_di/test/di.dart:177:7',
    superClass: ConditionalBaseDescriptor,
    annotations: [
      Injectable(),
      Conditional(requires: feature("dev"))
    ],
    constructor: () => ConditionalDev(),
    fromArrayConstructor: (List<dynamic> args) => ConditionalDev(),
  );

  var RootTypeDescriptor = type<RootType>(
    location: 'asset:velix_di/test/di.dart:182:16',
    annotations: [
      Injectable()
    ],
    isAbstract: true,
  );

  type<DerivedType>(
    location: 'asset:velix_di/test/di.dart:187:7',
    superClass: RootTypeDescriptor,
    annotations: [
      Injectable()
    ],
    constructor: () => DerivedType(),
    fromArrayConstructor: (List<dynamic> args) => DerivedType(),
  );

  type<Types>(
    location: 'asset:velix_di/test/di.dart:192:7',
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

  type<Invoice>(
    location: 'asset:velix_di/test/di.dart:226:7',
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

  type<Flat>(
    location: 'asset:velix_di/test/di.dart:234:7',
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<String>('priceCurrency', isNamed: true, isRequired: true), 
      param<int>('priceValue', isNamed: true, isRequired: true)
    ],
    constructor: ({String id = '', String priceCurrency = '', int priceValue = 0}) => Flat(id: id, priceCurrency: priceCurrency, priceValue: priceValue),
    fromArrayConstructor: (List<dynamic> args) => Flat(id: args[0] as String? ?? '', priceCurrency: args[1] as String? ?? '', priceValue: args[2] as int? ?? 0),
    fields: [
      field<Flat,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => obj.id,
      ), 
      field<Flat,String>('priceCurrency',
        getter: (obj) => obj.priceCurrency,
      ), 
      field<Flat,int>('priceValue',
        getter: (obj) => obj.priceValue,
      )
    ]
  );

  type<Immutable>(
    location: 'asset:velix_di/test/di.dart:250:7',
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
