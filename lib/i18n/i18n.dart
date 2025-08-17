/// a simple abstract class to have a common interface for i18n requests.
abstract class Translator {
  // static

  static Translator instance = NoTranslator();

  // static methods

  /// translate the given key and possible named arguments that will be interpolated
  /// [key] the key
  /// [args] and named arguments
  static String tr(String key, {Map<String, String> args = const {}}) {
    return instance.translate(key,  args:   args);
  }

  // constructor

  const Translator();
  
  String translate(String key, {Map<String, String> args = const {}});
}

/// @internal
class NoTranslator extends Translator {
  const NoTranslator();
  
  @override
  String translate(String key, {Map<String, String> args = const {}}) {
    return key;
  }
}

const Translator noTranslator = NoTranslator();

/// A [TranslationProvider] is able to translate a specific object type
/// [T] the object type
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

  /// translate an object
  /// [instance] the object instance
  String translate(T instance);
}

/// Registry for all [TranslationProvider]s
class TranslationManager {
  // static data

  static Map<Type,TranslationProvider> providers = {};

  // constructor

  // administration

  /// @internal
  static void register(TranslationProvider provider) {
    providers[provider.type] = provider;
  }

  // internal

  /// @internal
  static TranslationProvider? getProvider(dynamic instance) {
    return providers[instance.runtimeType];
  }

  // public

  /// translate the instance
  /// [instance] the instance
  static String translate(dynamic instance) {
    return getProvider(instance)!.translate(instance);
  }
}