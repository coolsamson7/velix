import '../validation/validation.dart';

abstract class Translator {
  // static

  static late Translator instance = DummyTranslator();

  // static methods

  static String tr(String key, {Map<String, String> args = const {}}) {
    return instance.translate(key,  args:   args);
  }

  // constructor

  const Translator();
  
  String translate(String key, {Map<String, String> args = const {}});
}

class DummyTranslator extends Translator {
  const DummyTranslator();
  
  @override
  String translate(String key, {Map<String, String> args = const {}}) {
    return key;
  }
}

const Translator NO_TRANSLATOR = DummyTranslator();

abstract class TranslationProvider<T> {
  // instance data

  late Type type;

  // constructor

  TranslationProvider() {
    type = T;

    TranslationManager.register(this);
  }

  // public

  Type getType() {
    return type;
  }

  // abstract

  String translate(T instance);
}


class TranslationManager {
  // static data

  static Map<Type,TranslationProvider> providers = {};

  // constructor

  // administration

  static void register(TranslationProvider provider) {
    providers[provider.type] = provider;
  }

  // internal

  static TranslationProvider? getProvider(dynamic instance) {
    return providers[instance.runtimeType];
  }

  // public

  static String translate(dynamic instance) {
    return getProvider(instance)!.translate(instance);
  }
}