//library velix;

// imports

import './configuration/configuration.dart';

import 'package:velix/reflectable/reflectable.dart';

import './di/di.dart';

// configuration

export './configuration/configuration.dart';

// di

export './di/di.dart';

// trick to allow to reference generated code
part 'velix_di.type_registry.g.dart';

class Velix {
  static final bootstrap = _bootstrap();

  static void _bootstrap() {
    // initialize factories

    TypeParameterResolverFactory();
    ConfigurationValueParameterResolverFactory();

    // register

    registerVelixDescriptors();
  }
}