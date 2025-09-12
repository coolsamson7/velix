//library velix;

// imports

// imports ( required by the generated code )

import './configuration/configuration.dart';
import './configuration/source/json_source.dart';

import 'package:velix/reflectable/reflectable.dart';

import './di/di.dart';

// exports

// configuration

export './configuration/configuration.dart';
export './configuration/source/json_source.dart';

// di

export './di/di.dart';

// trick to allow to reference generated code
//part 'velix_di.type_registry.g.dart';
part 'velix_di.types.g.dart';

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