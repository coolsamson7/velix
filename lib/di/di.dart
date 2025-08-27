
// annotations

import '../reflectable/reflectable.dart';

class Injectable {
  final bool eager;
  final String scope;
  const Injectable({this.eager = true, this.scope = 'singleton'});
}

class Module {
  final List<Type> imports;
  const Module({required this.imports});
}

class OnInit {
  const OnInit();
}

class OnDestroy {
  const OnDestroy();
}

class scope {
  final String name;
  final bool register;

  const scope({required this.name, this.register = false});
}


class Scopes {
  static Map<String, Type> scopes = {
    "request": RequestScope,
    "singleton": SingletonScope,
  };

  static void register(String name, Type scope) {
    scopes[name] = scope;
  }

  static Scope get(String name, Environment environment) {
    return environment.get<Scope>(scopes[name]!);
  }
}

typedef ArgumentsProvider = List<dynamic> Function();

abstract class Scope {
  T get<T>(AbstractInstanceProvider<T> provider, Environment environment, ArgumentsProvider argumentProvider);
}

@scope(name: "singleton", register: false)
class SingletonScope extends Scope {
  // instance data

  dynamic value;

  // constructor

  SingletonScope();

  // implement

  @override
  T get<T>(AbstractInstanceProvider<T> provider, Environment environment, ArgumentsProvider argumentProvider) {
    value ??= provider.create(environment, argumentProvider());

    return value;
  }
}

@scope(name: "environment", register: false)
class EnvironmentScope extends SingletonScope {
  // constructor

  EnvironmentScope();
}

@scope(name: "request", register: false)
class RequestScope extends Scope {
  // implement

  @override
  T get<T>(AbstractInstanceProvider<T> provider, Environment environment, ArgumentsProvider argumentProvider) {
    return provider.create(environment,argumentProvider());
  }
}

// we need that to bootstrap the system

class SingletonScopeInstanceProvider extends InstanceProvider<SingletonScope> {
  // constructor

  SingletonScopeInstanceProvider() : super(type: SingletonScope, eager: false, scope: "singleton");

  // override

  @override
  SingletonScope create(Environment environment, [List args = const []]) {
    return SingletonScope();
  }
}

class RequestScopeInstanceProvider extends InstanceProvider<RequestScope> {
  // constructor

  RequestScopeInstanceProvider() : super(type: RequestScope, eager: false, scope: "request");

  // override

  @override
  RequestScope create(Environment environment, [List args = const []]) {
    return RequestScope();
  }
}

class EnvironmentScopeInstanceProvider extends InstanceProvider<EnvironmentScope> {
  // constructor

  EnvironmentScopeInstanceProvider() : super(type: EnvironmentScope, eager: false, scope: "request");

  // override

  @override
  EnvironmentScope create(Environment environment, [List args = const []]) {
    return EnvironmentScope();
  }
}

class DIException implements Exception {
  final String message;
  DIException(this.message);

  @override
  String toString() => 'DIException: $message';
}

class DIRegistrationException extends DIException {
  DIRegistrationException(String message) : super(message);
}

class DIRuntimeException extends DIException {
  DIRuntimeException(String message) : super(message);
}

enum Lifecycle {
  onInject,
  onInit,
  onRunning,
  onDestroy,
}

abstract class LifecycleProcessor {
  int get order;
  void processLifecycle(Lifecycle lifecycle, Object instance, Environment environment);
}

/// The Providers class is a static class used in the context of the registration and resolution of InstanceProviders.

class ResolveContext {
  // instance data

  final Map<Type, EnvironmentInstanceProvider> providers;
  final List<EnvironmentInstanceProvider> _path = [];

  // constructor

  ResolveContext(this.providers);

  // public

  // push a provider onto the resolution path
  void push(EnvironmentInstanceProvider provider) {
    _path.add(provider);
  }

  // pop the last provider
  void pop() {
    if (_path.isNotEmpty) {
      _path.removeLast();
    }
  }

  // require a provider for a given type
  EnvironmentInstanceProvider requireProvider(Type type) {
    final provider = providers[type];

    if (provider == null) {
      throw DIRegistrationException('Provider for $type is not defined');
    }

    if (_path.contains(provider)) {
      throw DIRegistrationException(cycleReport(provider));
    }

    return provider;
  }

  // report a cycle in the dependency graph
  String cycleReport(EnvironmentInstanceProvider provider) {
    final buffer = StringBuffer();

    for (var i = 0; i < _path.length; i++) {
      if (i > 0) buffer.write(' -> ');
        ;//buffer.write(_path[i].report());
    }

    //buffer.write(' <> ${provider.report()}');
    return buffer.toString();
  }
}

class Providers {
  // static data

  static final List<AbstractInstanceProvider> _check = [];
  static final Map<Type, List<AbstractInstanceProvider>> _providers = {};

  static bool resolved = false;

  // static methods

  /// Register a provider
  static void register(AbstractInstanceProvider provider) {
    _check.add(provider);

    final candidates = _providers[provider.type];
    if (candidates == null) {
      _providers[provider.type] = [provider];
    }
    else {
      candidates.add(provider);
    }
  }

  /// Check if a type is registered
  static bool isRegistered(Type type) {
    return _providers.containsKey(type);
  }

  /// Filter providers based on the given environment and provider filter
  static Map<Type, EnvironmentInstanceProvider> filter(Environment environment, bool Function(AbstractInstanceProvider) providerFilter) {
    final Map<Type, AbstractInstanceProvider> cache = {};

    // local helper: check if a provider applies

    bool providerApplies(AbstractInstanceProvider provider) {
      if (!providerFilter(provider)) {
        return false;
      }

      return true;
    }

    // local helper: find matching provider for a type
    AbstractInstanceProvider? filterType(Type clazz) {
      AbstractInstanceProvider? result;

      final candidates = _providers[clazz];
      if (candidates != null) {
        for (final provider in candidates) {
          if (providerApplies(provider)) {
            if (result != null) {
              throw DIRegistrationException('type ${clazz.toString()} already registered');
            }

            result = provider;
          }
        }
      }

      return result;
    }

    // local helper: check if a type is injectable

    bool isInjectable(Type type) {
      if (type == Object) return false;
      if (type == AbstractInstanceProvider) return false; // Similar to ABC in Python
      return true; // No direct equivalent of inspect.isabstract
    }

    // local helper: cache provider for type (and its superclasses)
    void cacheProviderForType(AbstractInstanceProvider provider, Type type) {
      final existingProvider = cache[type];

      if (existingProvider == null) {
        cache[type] = provider;
      }
      else {
        if (type == provider.type) {
          throw DIRegistrationException('type ${type.toString()} already registered');
        }

        if (existingProvider.type != type) {
          if (existingProvider is AmbiguousProvider) {
            existingProvider.addProvider(provider);
          }
          else {
            cache[type] = AmbiguousProvider(type: type, providers: [existingProvider, provider]);
          }
        }
      }

      /* TODO Recursion for base classes (Dart doesn't have `__bases__`, so use reflection or manual hierarchy)
      final superClasses = TypeDescriptor.forType(type).getSuperTypes();
      for (final superClass in superClasses) {
        if (isInjectable(superClass)) {
          cacheProviderForType(provider, superClass);
        }
      }*/
    }

    // filter conditional providers and fill base classes as well

    for (final entry in _providers.entries) {
      final matchingProvider = filterType(entry.key);
      if (matchingProvider != null) {
        cacheProviderForType(matchingProvider, entry.key);
      }
    }

    // Replace by EnvironmentInstanceProvider

    final Map<AbstractInstanceProvider, EnvironmentInstanceProvider> mapped = {};
    final Map<Type, EnvironmentInstanceProvider> result = {};

    for (final entry in cache.entries) {
      var environmentProvider = mapped[entry.value];
      if (environmentProvider == null) {
        environmentProvider = EnvironmentInstanceProvider(environment: environment, provider: entry.value);
        mapped[entry.value] = environmentProvider;
      }

      result[entry.key] = environmentProvider;
    }

    // Merge parent providers

    var providers = result;
    if (environment.parent != null) {
      providers.addAll(environment.parent!.providers);
    }

    // Resolve providers

    final providerContext = ResolveContext(providers);
    for (final provider in mapped.values) {
      provider.resolve(providerContext);
    }

    return result;
  }
}


class Environment {
  // instance data

  Environment? parent;
  final Map<Type, EnvironmentInstanceProvider> providers = {};
  final List<String> features = [];
  final List<dynamic> instances  = [];
  final List<LifecycleProcessor> lifecycleProcessors  = [];

  // constructor

  Environment(Type module, {this.parent})  {
    if ( parent == null && module != Boot)
      parent = Boot.getEnvironment();

    _scan(module);

    final Stopwatch stopwatch = Stopwatch()..start();

    //Environment.logger.debug('create environment for class $type');

    void addProvider(Type type, AbstractInstanceProvider provider) {
      //Environment.logger.debug('\tadd provider $provider for $type');
      providers[type] = provider is EnvironmentInstanceProvider
          ? provider
          : EnvironmentInstanceProvider(environment: this, provider: provider);
    }

    // inherit parent providers

    if (parent != null) {
      parent!.providers.forEach((providerType, inheritedProvider) {
        var provider = inheritedProvider;
        if (inheritedProvider.scope == 'environment') {
          provider = EnvironmentInstanceProvider(environment: this, provider: inheritedProvider.provider);
          provider.dependencies = [];
        }
        addProvider(providerType, provider);
      });

      // inherit lifecycle processors

      for (final processor in parent!.lifecycleProcessors) {
        if (providers[processor.runtimeType]?.scope != 'environment') {
          lifecycleProcessors.add(processor);
        }
        else {
          get(processor.runtimeType); // automatically appends
        }
      }
    }
    else {
      providers[SingletonScope] = EnvironmentInstanceProvider(environment: this, provider: SingletonScopeInstanceProvider());
      providers[RequestScope] = EnvironmentInstanceProvider(environment: this, provider: RequestScopeInstanceProvider());
      providers[EnvironmentScope] = EnvironmentInstanceProvider(environment: this, provider: EnvironmentScopeInstanceProvider());
    }

    final Set<Type> loadedEnvironments = {};
    final List<String> prefixList = [];

    // Helper: get package/module name (best-effort)
    // TODO
    String getTypePackage(Type type) {
      // Dart does not have __module__, __package__; use library metadata if available
      // Fallback: use type.toString() as identifier
      return type.toString().split('.').first;
    }

    // Helper: filter provider by prefix
    // TODO?????
    bool filterProvider(AbstractInstanceProvider provider) {
      final hostModule = provider.host.toString();
      for (final prefix in prefixList) {
        if (hostModule.startsWith(prefix)) return true;
      }
      return false;
    }

    // Recursively load environment and its dependencies
    void loadEnvironment(Type envType) {
      if (!loadedEnvironments.contains(envType)) {
        //Environment.logger.debug('load environment $envType');
        loadedEnvironments.add(envType);

        final decorator = TypeDescriptor.forType(envType).find_annotation<Module>();
        if (decorator == null) {
          throw DIRegistrationException('$envType is not an module class');
        }

        // Load dependencies recursively

        //TODO final importEnvironments = decorator.args.isNotEmpty ? decorator.args[0] as List<Type> : [];
        //for (final importEnv in importEnvironments) {
        //  loadEnvironment(importEnv);
        //}

        // Determine package prefix

        final packageName = getTypePackage(envType);
        if (packageName.isNotEmpty) {
          prefixList.add(packageName);
          // In Dart, there’s no dynamic import at runtime, so skip `import_package`
        }
      }
    }

    loadEnvironment(module);

    // filter providers according to prefix list

    providers.addAll(Providers.filter(this, filterProvider));

    // Construct eager objects for local providers

    for (final provider in providers.values.toSet()) {
      if (provider.eager) {
        provider.create(this);
      }
    }

    // TODO Run ON_RUNNING lifecycle callbacks
    //for (final instance in instances) {
    //  executeProcessors(Lifecycle.ON_RUNNING, instance);
    //}

    stopwatch.stop();
    //Environment.logger.info(
    //    'created environment for class $type in ${stopwatch.elapsedMilliseconds} ms, created ${instances.length} instances');
  }
  
  void _scan(Type module) {
    var descriptor = TypeDescriptor.forType(module);
    var name = descriptor.name;

    int index = name.lastIndexOf('/');
    var prefix = index == -1 ? name : name.substring(0, index);

    // register module

    Providers.register(ClassInstanceProvider(module));

    // scan everything under it

    for ( var type in TypeDescriptor.types()) {
      if ( type != descriptor && type.name.startsWith(prefix)) {
        var annotation = type.find_annotation<Injectable>();
        if ( annotation != null) {
          Providers.register(ClassInstanceProvider(type.type, eager: annotation.eager, scope: annotation.scope));
        }
      }
    }
  }

  T get<T>(Type t) {
    final provider = providers[T];
    if (provider == null) {
      throw DIRuntimeException('$T is not supported');
    }

    return provider.create(this) as T;
  }

  T created<T>(T instance) {
    return instance; // TODO
  }

  void initialize() {
    for (var provider in providers.values) {
      if (provider.eager) {
        provider.create(this);
      }
    }
  }
}

abstract class AbstractInstanceProvider<T> {
  // instance data

  Type get host => runtimeType;
  Type get type;
  bool get eager;
  String get scope;

  // abstract

  (List<Type>,int) getDependencies() {
    return ([], 1);
  }

  T create(Environment environment, [List<dynamic> args = const []]) {
     throw UnimplementedError();
  }
}

 abstract class InstanceProvider<T> extends AbstractInstanceProvider<T> {
  // instance data

  late Type _host;
  final Type _type;
  final bool _eager;
  final String _scope;

  // constructor

  InstanceProvider({required Type type, Type? host, bool eager = true, String scope = "singleton"})
  : _type = type, _eager = eager, _scope = scope {
  _host = host ?? runtimeType;
 }

  // override

  @override
  bool get eager => _eager;

  @override
  String get scope => _scope;

  @override
  Type get type => _type;

  @override
  Type get host => _host;
}

class EnvironmentInstanceProvider<T> extends AbstractInstanceProvider<T> {
  // instance data

  final Environment environment;
  final AbstractInstanceProvider<T> provider;

  List<EnvironmentInstanceProvider>? dependencies;
  Scope scopeInstance;

  // constructor

  EnvironmentInstanceProvider({required this.environment, required this.provider})
      : scopeInstance = Scopes.get(provider.scope, environment);

  // internal

  void resolve(ResolveContext context) {
    if (dependencies == null) {
      dependencies = [];

      context.push(this);
      try {
        final (types, params) = provider.getDependencies();

        for (final type in types) {
          final depProvider = context.requireProvider(type);

          dependencies!.add(depProvider);
          depProvider.resolve(context);
        }
      }
      finally {
        context.pop();
      }
    }
  }

  // override

  @override
  T create(Environment environment, [List<dynamic> args = const []]) {
    return scopeInstance.get<T>(provider, environment,  () => dependencies!.map((dependency) => dependency.create(environment)).toList(growable: false));
  }

  @override
  bool get eager => provider.eager;

  @override
  String get scope => provider.scope;

  @override
  Type get type => provider.type;
}

class AmbiguousProvider<T> extends InstanceProvider<T> {
  // instance data

  List<AbstractInstanceProvider<T>> providers = [];

  // constructor

  AmbiguousProvider({required super.type, required this.providers});

  // public

  void addProvider(AbstractInstanceProvider<T> provider) {
    providers.add(provider);
  }
}

class ClassInstanceProvider<T> extends InstanceProvider<T> {
  // instance data

  final TypeDescriptor descriptor;

  // constructor

  ClassInstanceProvider(Type type, {bool eager = true, String scope = 'singleton'})
      : descriptor = TypeDescriptor.forType(type), super(type: type, host: type, eager: eager, scope: scope) ;

  // override

  /// Returns the list of dependency types and the number of constructor parameters
   @override
  (List<Type>,int) getDependencies() {
    final List<Type> types = [];
    int params = 0;

    // Check constructor parameters

    final constructorParams = descriptor.constructorParameters;

    params = descriptor.constructorParameters.length;
    types.addAll(constructorParams.map((param) => param.type));

    /* TODO Check methods annotated with @inject

    for (final method in TypeDescriptor.forType(type).getMethods()) {
      if (method.hasDecorator(inject)) {
      for (final param in method.paramTypes) {
        if (!Providers.isRegistered(param)) {
          throw DIRegistrationException(
          '${type.toString()}.${method.method.name} declares an unknown parameter type ${param.toString()}');
        }
        types.add(param);
        }
      } // if
    } // for
    */

    return (types, params);
  }

  /// Creates an instance of the type using the environment
  ///
  @override
  T create(Environment environment, [List<dynamic> args = const []]) {
    final instance = descriptor.fromArrayConstructor(args);

    return environment.created(instance);
    }
}

// boot

@Module(imports: [])
class Boot {
  static Environment? environment;

  static Environment getEnvironment() {
    environment ??= Environment(Boot);

    return environment!;
  }
}