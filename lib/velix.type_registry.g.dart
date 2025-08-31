// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'package:velix/configuration/source/json_source.dart';
import 'package:velix/di/di.dart';
import 'package:velix/configuration/configuration.dart';

void registerAllDescriptors() {
  var ConfigurationSourceDescriptor = type<ConfigurationSource>(
    location: 'package:velix/configuration/configuration.dart:137:16',
    annotations: [
      Injectable(factory: false)
    ],
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
    fromMapConstructor: (Map<String,dynamic> args) => JsonFileConfigurationSource(args['filePath'] as String),
    fromArrayConstructor: (List<dynamic> args) => JsonFileConfigurationSource(args[0] as String),
  );

  type<ConfigurationManager>(
    location: 'package:velix/configuration/configuration.dart:32:7',
    annotations: [
      Injectable(factory: false)
    ],
    constructor: () => ConfigurationManager(),
    fromMapConstructor: (Map<String,dynamic> args) => ConfigurationManager(),
    fromArrayConstructor: (List<dynamic> args) => ConfigurationManager(),
  );

  type<ConfigurationValues>(
    location: 'package:velix/configuration/configuration.dart:150:7',
    superClass: ConfigurationSourceDescriptor,
    annotations: [
      Injectable(factory: false)
    ],
    params: [
      param<Map<String, dynamic>>('values', isRequired: true)
    ],
    constructor: ({required Map<String, dynamic> values}) => ConfigurationValues(values),
    fromMapConstructor: (Map<String,dynamic> args) => ConfigurationValues(args['_config'] as Map<String, dynamic>),
    fromArrayConstructor: (List<dynamic> args) => ConfigurationValues(args[0] as Map<String, dynamic>),
  );

  type<SingletonScope>(
    location: 'package:velix/di/di.dart:180:7',
    annotations: [
      Scope(name: "singleton", register: false)
    ],
    constructor: () => SingletonScope(),
    fromMapConstructor: (Map<String,dynamic> args) => SingletonScope(),
    fromArrayConstructor: (List<dynamic> args) => SingletonScope(),
  );

  type<EnvironmentScope>(
    location: 'package:velix/di/di.dart:200:7',
    annotations: [
      Scope(name: "environment", register: false)
    ],
    constructor: () => EnvironmentScope(),
    fromMapConstructor: (Map<String,dynamic> args) => EnvironmentScope(),
    fromArrayConstructor: (List<dynamic> args) => EnvironmentScope(),
  );

  type<RequestScope>(
    location: 'package:velix/di/di.dart:207:7',
    annotations: [
      Scope(name: "request", register: false)
    ],
    constructor: () => RequestScope(),
    fromMapConstructor: (Map<String,dynamic> args) => RequestScope(),
    fromArrayConstructor: (List<dynamic> args) => RequestScope(),
  );

  type<OnInitProcessor>(
    location: 'package:velix/di/di.dart:405:7',
    annotations: [
      Injectable(eager: false)
    ],
    constructor: () => OnInitProcessor(),
    fromMapConstructor: (Map<String,dynamic> args) => OnInitProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnInitProcessor(),
  );

  type<OnRunningProcessor>(
    location: 'package:velix/di/di.dart:431:7',
    annotations: [
      Injectable(eager: false)
    ],
    constructor: () => OnRunningProcessor(),
    fromMapConstructor: (Map<String,dynamic> args) => OnRunningProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnRunningProcessor(),
  );

  type<OnDestroyProcessor>(
    location: 'package:velix/di/di.dart:457:7',
    annotations: [
      Injectable(eager: false)
    ],
    constructor: () => OnDestroyProcessor(),
    fromMapConstructor: (Map<String,dynamic> args) => OnDestroyProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnDestroyProcessor(),
  );

  type<Boot>(
    location: 'package:velix/di/di.dart:1319:7',
    annotations: [
      Module(imports: [])
    ],
    constructor: () => Boot(),
    fromMapConstructor: (Map<String,dynamic> args) => Boot(),
    fromArrayConstructor: (List<dynamic> args) => Boot(),
  );
}
