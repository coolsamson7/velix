// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'package:velix/configuration/configuration.dart';
import 'package:velix/di/di.dart';

void registerAllDescriptors() {
  type<ConfigurationManager>(
    location: 'package:velix/configuration/configuration.dart:32:7',
    annotations: [
      Injectable(factory: false)
    ],
    params: [
    ],
    constructor: () => ConfigurationManager(),
    fromMapConstructor: (Map<String,dynamic> args) => ConfigurationManager(),
    fromArrayConstructor: (List<dynamic> args) => ConfigurationManager(),
    fields: [
    ]
  );

  type<OnInitCallableProcessor>(
    location: 'package:velix/di/di.dart:405:7',
    annotations: [
      Injectable()
    ],
    params: [
    ],
    constructor: () => OnInitCallableProcessor(),
    fromMapConstructor: (Map<String,dynamic> args) => OnInitCallableProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnInitCallableProcessor(),
    fields: [
    ]
  );

  type<OnRunningCallableProcessor>(
    location: 'package:velix/di/di.dart:431:7',
    annotations: [
      Injectable()
    ],
    params: [
    ],
    constructor: () => OnRunningCallableProcessor(),
    fromMapConstructor: (Map<String,dynamic> args) => OnRunningCallableProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnRunningCallableProcessor(),
    fields: [
    ]
  );

  type<OnDestroyCallableProcessor>(
    location: 'package:velix/di/di.dart:457:7',
    annotations: [
      Injectable()
    ],
    params: [
    ],
    constructor: () => OnDestroyCallableProcessor(),
    fromMapConstructor: (Map<String,dynamic> args) => OnDestroyCallableProcessor(),
    fromArrayConstructor: (List<dynamic> args) => OnDestroyCallableProcessor(),
    fields: [
    ]
  );

  type<Boot>(
    location: 'package:velix/di/di.dart:1319:7',
    annotations: [
      Module(imports: [])
    ],
    params: [
    ],
    constructor: () => Boot(),
    fromMapConstructor: (Map<String,dynamic> args) => Boot(),
    fromArrayConstructor: (List<dynamic> args) => Boot(),
    fields: [
    ]
  );
}
