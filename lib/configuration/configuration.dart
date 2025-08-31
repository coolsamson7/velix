import '../di/di.dart';
import '../reflectable/reflectable.dart';


/// Exception raised for errors in the configuration logic.
class ConfigurationException implements Exception {
  final String message;
  final Exception? cause;

  const ConfigurationException(this.message, [this.cause]);

  @override
  String toString() => 'ConfigurationException: $message';
}


/// InjectValue annotation for configuration value injection
class Value {
  final String key;
  final dynamic defaultValue;

  const Value(this.key, {this.defaultValue});
}


/// Type coercion functions
typedef CoercionFunction<T> = T Function(dynamic value);

/// ConfigurationManager is responsible for managing different configuration sources
/// by merging the different values and offering a uniform API.
@Injectable(factory: false)
class ConfigurationManager {
  // instance data

  final List<ConfigurationSource> _sources = [];
  Map<String, dynamic> _data = {};
  late final Map<Type, CoercionFunction> _coercions;

  // constructor

  ConfigurationManager() {
    _coercions = {
      int: (v) => v is int ? v : int.parse(v.toString()),
      double: (v) => v is double ? v : double.parse(v.toString()),
      bool: (v) => v is bool ? v : _parseBool(v.toString()),
      String: (v) => v.toString(),
    };
  }

  bool _parseBool(String value) {
    final lower = value.toLowerCase();
    return lower == '1' ||
        lower == 'true' ||
        lower == 'yes' ||
        lower == 'on';
  }

  /// Internal method to register a configuration source
  void _register(ConfigurationSource source) {
    _sources.add(source);
    loadSource(source);
  }

  /// Load configuration data from a source
  void loadSource(ConfigurationSource source) {
    _data = _mergeMaps(_data, source.load());
  }

  /// Merge two maps recursively
  Map<String, dynamic> _mergeMaps(Map<String, dynamic> a, Map<String, dynamic> b) {
    final result = Map<String, dynamic>.from(a);

    for (final entry in b.entries) {
      final key = entry.key;
      final bVal = entry.value;

      if (result.containsKey(key)) {
        final aVal = result[key];
        if (aVal is Map<String, dynamic> && bVal is Map<String, dynamic>) {
          result[key] = _mergeMaps(aVal, bVal); // Recurse
        } else {
          result[key] = bVal; // Overwrite
        }
      } else {
        result[key] = bVal;
      }
    }

    return result;
  }

  /// Retrieve a configuration value by path and type, with optional coercion.
  ///
  /// [path] The path to the configuration value, e.g. "database.host".
  /// [type] The expected type.
  /// [defaultValue] The default value to return if the path is not found.
  ///
  /// Returns the configuration value coerced to the specified type,
  /// or the default value if not found.
  T get<T>(String path, Type type, [T? defaultValue]) {
    final value = _resolveValue(path, defaultValue);

    if (value.runtimeType == type) {
      return value as T;
    }

    if (_coercions.containsKey(type)) {
      try {
        return _coercions[type]!(value) as T;
      }
      catch (e) {
        throw ConfigurationException('Error during coercion to $type', e as Exception?);
      }
    } else {
      throw ConfigurationException('Unknown coercion to $type');
    }
  }

  /// Resolve a value from the configuration data by path
  dynamic _resolveValue(String path, [dynamic defaultValue]) {
    final keys = path.split('.');
    dynamic current = _data;

    for (final key in keys) {
      if (current is! Map<String, dynamic> || !current.containsKey(key)) {
        return defaultValue;
      }
      current = current[key];
    }

    return current;
  }
}

/// Abstract base class for configuration sources
@Injectable(factory: false)
abstract class ConfigurationSource {
  @Inject()
  void setManager(ConfigurationManager manager) {
    manager._register(this);
  }

  /// Return the configuration values of this source as a dictionary.
  Map<String, dynamic> load();
}

/// In-memory configuration source for testing

@Injectable(factory: false)
class ConfigurationValues extends ConfigurationSource {
  final Map<String, dynamic> _config;

  ConfigurationValues(Map<String, dynamic> values) : _config = values;

  @override
  Map<String, dynamic> load() => Map.from(_config);
}


class ConfigurationValueParameterResolver extends ParameterResolver {
  // instance data

  Value injectValue;
  Type type;

  // constructor

  ConfigurationValueParameterResolver({required this.injectValue, required this.type});

  // override

  @override
  List<Type> requires() => [ConfigurationManager];

  @override
  dynamic resolve(Environment environment) {
    return environment.get<ConfigurationManager>().get(injectValue.key, type, injectValue.defaultValue);
  }
}

class ConfigurationValueParameterResolverFactory extends ParameterResolverFactory {
  // constructor

  ConfigurationValueParameterResolverFactory() {
    ParameterResolverFactory.register(this);
  }

  // override

  @override
  bool applies(Environment environment, ParameterDescriptor parameter) {
    return parameter.getAnnotation<Value>() != null;
  }

  @override
  ParameterResolver create(Environment environment, ParameterDescriptor parameter) {
    return ConfigurationValueParameterResolver(injectValue: parameter.getAnnotation<Value>()!, type: parameter.type);
  }
}
