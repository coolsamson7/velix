// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
//import 'package:velix/velix.dart';
part of 'velix.dart';

void registerVelixDescriptors() {
  var ConfigurationSourceDescriptor = type<ConfigurationSource>(
    location: 'package:velix/configuration/configuration.dart:139:16',
    annotations: [
      Injectable(factory: false)
    ],
    isAbstract: true,
    methods: [
      method<ConfigurationSource,void>('setManager',
        annotations: [
          Inject()
        ],
        parameters: [
          param<ConfigurationManager>('manager', isRequired: true)
        ],
        invoker: (List<dynamic> args)=> (args[0] as ConfigurationSource).setManager(args[1 ])
      )
    ],
  );

  type<JsonFileConfigurationSource>(
    location: 'package:velix/configuration/source/json_source.dart:8:7',
    superClass: ConfigurationSourceDescriptor,
    annotations: [
      Injectable(factory: false)
    ],
    params: [
      param<String>('filePath', isRequired: true)
    ],
    constructor: ({String filePath = ''}) => JsonFileConfigurationSource(filePath),
    fromArrayConstructor: (List<dynamic> args) => JsonFileConfigurationSource(args[0] as String),
  );

  type<ConfigurationManager>(
    location: 'package:velix/configuration/configuration.dart:32:7',
    annotations: [
      Injectable(factory: false)
    ],
    constructor: () => ConfigurationManager(),
    fromArrayConstructor: (List<dynamic> args) => ConfigurationManager(),
  );

  type<ConfigurationValues>(
    location: 'package:velix/configuration/configuration.dart:152:7',
    superClass: ConfigurationSourceDescriptor,
    annotations: [
      Injectable(factory: false)
    ],
    params: [
      param<Map<String, dynamic>>('values', isRequired: true)
    ],
    constructor: ({required Map<String, dynamic> values}) => ConfigurationValues(values),
    fromArrayConstructor: (List<dynamic> args) => ConfigurationValues(args[0] as Map<String, dynamic>),
  );

  type<SingletonScope>(
    location: 'package:velix/di/di.dart:167:7',
    annotations: [
      Scope(name: "singleton", register: false)
    ],
    constructor: () => SingletonScope(),
    fromArrayConstructor: (List<dynamic> args) => SingletonScope(),
  );

  type<EnvironmentScope>(
    location: 'package:velix/di/di.dart:187:7',
    annotations: [
      Scope(name: "environment", register: false)
    ],
    constructor: () => EnvironmentScope(),
    fromArrayConstructor: (List<dynamic> args) => EnvironmentScope(),
  );

  type<RequestScope>(
    location: 'package:velix/di/di.dart:194:7',
    annotations: [
      Scope(name: "request", register: false)
    ],
    constructor: () => RequestScope(),
    fromArrayConstructor: (List<dynamic> args) => RequestScope(),
  );

  type<OnInjectProcessor>(
    location: 'package:velix/di/di.dart:441:7',
    annotations: [
      Injectable(eager: false)
    ],
    constructor: () => OnInjectProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnInjectProcessor(),
  );

  type<OnInitProcessor>(
    location: 'package:velix/di/di.dart:446:7',
    annotations: [
      Injectable(eager: false)
    ],
    constructor: () => OnInitProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnInitProcessor(),
  );

  type<OnRunningProcessor>(
    location: 'package:velix/di/di.dart:451:7',
    annotations: [
      Injectable(eager: false)
    ],
    constructor: () => OnRunningProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnRunningProcessor(),
  );

  type<OnDestroyProcessor>(
    location: 'package:velix/di/di.dart:456:7',
    annotations: [
      Injectable(eager: false)
    ],
    constructor: () => OnDestroyProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnDestroyProcessor(),
  );

  type<Boot>(
    location: 'package:velix/di/di.dart:1324:7',
    annotations: [
      Module(imports: [])
    ],
    constructor: () => Boot(),
    fromArrayConstructor: (List<dynamic> args) => Boot(),
  );
}
