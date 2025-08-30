import '../configuration/configuration.dart';
import '../reflectable/reflectable.dart';
import '../util/tracer.dart';
import '../velix.type_registry.g.dart';

// annotations

/// Context for condition evaluation
class ConditionContext {
  final bool Function(String) requiresFeature;

  const ConditionContext({
    required this.requiresFeature,
  });
}

/// Abstract base class for conditions
mixin Condition {
  bool apply(ConditionContext context);
}

/// Condition that checks for a specific feature
class FeatureCondition with Condition {
  final String feature;

  const FeatureCondition(this.feature);

  @override
  bool apply(ConditionContext context) {
    return context.requiresFeature(feature);
  }
}

FeatureCondition requiresFeature(String feature) {
  return FeatureCondition(feature);
}

class Conditional extends ClassAnnotation {
  final String feature;

  // constructor

  const Conditional(this. feature);

  // override

  @override
  void apply(TypeDescriptor type) {

  }
}

class Injectable extends ClassAnnotation {
  final bool eager;
  final String scope;
  final bool factory;

  // constructor

  const Injectable({this.factory = true, this.eager = true, this.scope = 'singleton'});

  // override

  @override
  void apply(TypeDescriptor type) {
    if (factory)
      Providers.register(ClassInstanceProvider(type.type, eager: eager, scope: scope));
  }
}

class Create extends MethodAnnotation {
  const Create();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    Providers.register(FunctionInstanceProvider(type.type, method));
  }
}

class Module extends ClassAnnotation {
  final List<Type> imports;

  // constructor

  const Module({List<Type>? imports}) : imports = imports ?? const [];

  // override

  @override
  void apply(TypeDescriptor type) {
    Providers.register(ClassInstanceProvider(type.type, eager: true));
  }
}

class OnInit extends MethodAnnotation {
  const OnInit();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    OnInitCallableProcessor.register(type, method);
  }
}

class OnRunning extends MethodAnnotation {
  const OnRunning();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    OnRunningCallableProcessor.register(type, method);
  }
}

class Inject extends MethodAnnotation {
  const Inject();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    OnInjectCallableProcessor.register(type, method);
  }
}

class OnDestroy extends MethodAnnotation {
  const OnDestroy();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    OnDestroyCallableProcessor.register(type, method);
  }
}

class Scope extends ClassAnnotation {
  final String name;
  final bool register;

  // constructor

  const Scope({required this.name, this.register = false});

  // override

  @override
  void apply(TypeDescriptor type) {
    Scopes.register(name, type.type);

    if (register)
      Providers.register(ClassInstanceProvider(type.type, eager: true, scope: "request"));
  }
}


class Scopes {
  static Map<String, Type> scopes = {};

  static void register(String name, Type scope) {
    scopes[name] = scope;
  }

  static AbstractScope get(String name, Environment environment) {
    Type type = scopes[name]!;
    return environment.get(type: type);
  }
}

typedef ArgumentsProvider = List<dynamic> Function();

abstract class AbstractScope {
  T get<T>(AbstractInstanceProvider<T> provider, Environment environment, ArgumentsProvider argumentProvider);
}

@Scope(name: "singleton", register: false)
class SingletonScope extends AbstractScope {
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

@Scope(name: "environment", register: false)
class EnvironmentScope extends SingletonScope {
  // constructor

  EnvironmentScope();
}

@Scope(name: "request", register: false)
class RequestScope extends AbstractScope {
  // implement

  @override
  T get<T>(AbstractInstanceProvider<T> provider, Environment environment, ArgumentsProvider argumentProvider) {
    return provider.create(environment,argumentProvider());
  }
}

// we need that to bootstrap the system

class SingletonScopeInstanceProvider extends InstanceProvider<SingletonScope> {
  // constructor

  SingletonScopeInstanceProvider() : super(type: SingletonScope, eager: false, scope: "request");

  // override

  @override
  SingletonScope create(Environment environment, [List args = const []]) {
    return SingletonScope();
  }

  // override Object

  @override
  String toString() => "SingletonScopeInstanceProvider";
}

class RequestScopeInstanceProvider extends InstanceProvider<RequestScope> {
  // constructor

  RequestScopeInstanceProvider() : super(type: RequestScope, eager: false, scope: "singleton");

  // override

  @override
  RequestScope create(Environment environment, [List args = const []]) {
    return RequestScope();
  }

  // override Object

  @override
  String toString() => "RequestScopeInstanceProvider";
}

class EnvironmentScopeInstanceProvider extends InstanceProvider<EnvironmentScope> {
  // constructor

  EnvironmentScopeInstanceProvider() : super(type: EnvironmentScope, eager: false, scope: "request");

  // override

  @override
  EnvironmentScope create(Environment environment, [List args = const []]) {
    return EnvironmentScope();
  }

  // override Object

  @override
  String toString() => "EnvironmentScopeInstanceProvider";
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
  // instance data

  int get order;
  final Lifecycle lifecycle;

  // constructor

  LifecycleProcessor({required this.lifecycle});

  // public

  void processLifecycle(dynamic instance, Environment environment);
}

class MethodCall {
  // instance data

  final MethodDescriptor method;
  List<ArgumentResolver>? resolvers;

  // constructor

  MethodCall({required this.method});

  // public

  void resolve(Environment environment, Set<Type> types) {
    if ( resolvers == null) {
      resolvers = [];
      for (var parameter in method.parameters) {
        var resolver = ParameterResolverFactory.createResolver(
            environment, parameter);

        types.addAll(resolver.requires());

        resolvers!.add(resolver);
      }
    }
  }

  void execute(dynamic instance, Environment environment) {
    method.invoker!(ArgumentResolver.createReceiverArgs(environment, instance, resolvers!));
  }
}

 abstract class AbstractCallableProcessor extends LifecycleProcessor {
  // constructor

  AbstractCallableProcessor({required super.lifecycle});

  // override

  @override
  // TODO: implement order
  int get order => 1;

  void execute(List<MethodCall>? methods, instance, environment) {
    if ( methods != null)
      for ( var method in methods)
        method.execute(instance, environment);
  }
}

/// base class for post processors
abstract class PostProcessor extends LifecycleProcessor {
  @override
  // TODO: implement order
  int get order => 1;

  void process(dynamic instance, Environment environment);

  // constructor

  PostProcessor():super(lifecycle: Lifecycle.onInit);

  // override

  @override
  void processLifecycle(instance, Environment environment) {
    process(instance, environment);
  }
}

class OnInjectCallableProcessor extends AbstractCallableProcessor {
  // static

  static Map<Type, List<MethodCall>> methods = {};

  static void register(TypeDescriptor type, MethodDescriptor method) {
    var list = methods[type.type];
    if ( list == null)
      methods[type.type] = [MethodCall(method: method)];
    else
      methods[type.type]!.add(MethodCall(method: method));
  }

  // constructor

  OnInjectCallableProcessor(): super(lifecycle: Lifecycle.onInject);

  // override

  @override
  void processLifecycle(instance, Environment environment) {
    execute(methods[instance.runtimeType], instance, environment);
  }
}

@Injectable()
class OnInitCallableProcessor extends AbstractCallableProcessor {
  // static

  static Map<Type, List<MethodCall>> methods = {};

  static void register(TypeDescriptor type, MethodDescriptor method) {
    var list = methods[type.type];
    if ( list == null)
      methods[type.type] = [MethodCall(method: method)];
    else
      methods[type.type]!.add(MethodCall(method: method));
  }

  // constructor

  OnInitCallableProcessor(): super(lifecycle: Lifecycle.onInit);

  // override

  @override
  void processLifecycle(instance, Environment environment) {
    execute(methods[instance.runtimeType], instance, environment);
  }
}

@Injectable()
class OnRunningCallableProcessor extends AbstractCallableProcessor {
  // static

  static Map<Type, List<MethodCall>> methods = {};

  static void register(TypeDescriptor type, MethodDescriptor method) {
    var list = methods[type.type];
    if ( list == null)
      methods[type.type] = [MethodCall(method: method)];
    else
      methods[type.type]!.add(MethodCall(method: method));
  }

  // constructor

  OnRunningCallableProcessor(): super(lifecycle: Lifecycle.onRunning);

  // override

  @override
  void processLifecycle(instance, Environment environment) {
    execute(methods[instance.runtimeType], instance, environment);
  }
}

@Injectable()
class OnDestroyCallableProcessor extends AbstractCallableProcessor {
  // static

  static Map<Type, List<MethodCall>> methods = {};

  static void register(TypeDescriptor type, MethodDescriptor method) {
    var list = methods[type.type];
    if ( list == null)
      methods[type.type] = [MethodCall(method: method)];
    else
      methods[type.type]!.add(MethodCall(method: method));
  }

  // constructor

  OnDestroyCallableProcessor(): super(lifecycle: Lifecycle.onDestroy);

  @override
  void processLifecycle(instance, Environment environment) {
    execute(methods[instance.runtimeType], instance, environment);
  }
}

/// The Providers class is a static class used in the context of the registration and resolution of InstanceProviders.

class ResolveContext {
  // instance data

  final Map<Type, AbstractInstanceProvider> providers;
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
      throw DIRegistrationException(cycleReport(provider as EnvironmentInstanceProvider));
    }

    return provider as EnvironmentInstanceProvider;
  }

  // report a cycle in the dependency graph
  String cycleReport(EnvironmentInstanceProvider provider) {
    final buffer = StringBuffer();

    for (var i = 0; i < _path.length; i++) {
      if (i > 0)
        buffer.write(' -> ');

      buffer.write(_path[i].report());
    }

    buffer.write(' <> ${provider.report()}');

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
  static Map<Type, AbstractInstanceProvider> filter(Environment environment, bool Function(AbstractInstanceProvider) providerFilter) {
    final Map<Type, AbstractInstanceProvider> cache = {};

    // local helper: check if a provider applies

    bool providerApplies(AbstractInstanceProvider provider) {
      if (!providerFilter(provider)) {
        return false;
      }

      // check conditionals

      var descriptor = TypeDescriptor.forType(provider.host);

      Conditional? conditional = descriptor.getAnnotation<Conditional>();
      if ( conditional != null) {
        if (!environment.hasFeature(conditional.feature))
          return false;
      }

      // ok

      return true;
    }

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

    bool isInjectable(TypeDescriptor type) {
      return type.findAnnotation<Injectable>() != null;
    }

    void cacheProviderForType(AbstractInstanceProvider provider, Type type) {
      final existingProvider = cache[type];

      if (existingProvider == null) {
        cache[type] = provider;
      }
      else {
        if (type == provider.type) {
          throw DIRegistrationException('type $type already registered');
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

      final superClass = TypeDescriptor.forType(type).superClass;
        if (superClass != null && isInjectable(superClass)) {
          cacheProviderForType(provider, superClass.type);
        }
    }

    // filter conditional providers and fill base classes as well

    for (final entry in _providers.entries) {
      final matchingProvider = filterType(entry.key);

      if (matchingProvider != null) {
        cacheProviderForType(matchingProvider, entry.key);
      }
    }

    // replace by EnvironmentInstanceProvider

    final Map<AbstractInstanceProvider, AbstractInstanceProvider> mapped = {};
    final Map<Type, AbstractInstanceProvider> result = {};

    for (final entry in cache.entries) {
      var environmentProvider = mapped[entry.value];
      if (environmentProvider == null) {
        environmentProvider = EnvironmentInstanceProvider(environment: environment, provider: entry.value);
        mapped[entry.value] = environmentProvider;
      }

      result[entry.key] = environmentProvider;
    }

    // merge parent providers

    var providers = result;
    if (environment.parent != null) {
      providers.addAll(environment.parent!.providers);
    }

    // resolve providers

    final providerContext = ResolveContext(providers);
    for (final provider in mapped.values) {
      provider.resolve(providerContext);
    }

    return result;
  }
}

abstract class ParameterResolverFactory {
  // static data

  static List<ParameterResolverFactory> factories = [];

  // static

  static void register(ParameterResolverFactory factory) {
    factories.add(factory);
  }

  static ParameterResolver createResolver(Environment environment, ParameterDescriptor parameter) {
    for ( var factory in factories)
      if (factory.applies(environment, parameter))
        return factory.create(environment, parameter);

    throw DIRegistrationException("no resolver for parameter");
  }

  // abstract

  bool applies(Environment environment, ParameterDescriptor parameter);

  ParameterResolver create(Environment environment, ParameterDescriptor parameter);
}

class TypeParameterResolverFactory extends ParameterResolverFactory {
  // constructor

  TypeParameterResolverFactory() {
    ParameterResolverFactory.register(this);
  }

  // override

  @override
  bool applies(Environment environment, ParameterDescriptor parameter) {
    return true; // ?? environment.hasProvider(parameter.type);
  }

  @override
  ParameterResolver create(Environment environment, ParameterDescriptor parameter) {
    if ( parameter.type == Environment)
      return EnvironmentParameterResolver();
    else
     return TypeParameterResolver(type: parameter.type);
  }
}


abstract class ArgumentResolver {
  // static

  static List<dynamic> createReceiverArgs(Environment environment, dynamic instance, List<ArgumentResolver> resolvers) {
    var result = List<dynamic>.filled(resolvers.length + 1, null, growable: false);

    result[0] = instance;
    for (var i = 0; i < resolvers.length; i++)
      result[i + 1] = resolvers[i].resolve(environment);

    return result;
  }

  static List<dynamic> createArgs(Environment environment, List<ArgumentResolver> resolvers) {
    if (resolvers.isNotEmpty) {
      var result = List<dynamic>.filled(resolvers.length, null, growable: false);

      for (var i = 0; i < resolvers.length; i++)
        result[i] = resolvers[i].resolve(environment);

      return result;
    } // if
    else return const [];
  }

  dynamic resolve(Environment environment);
}

abstract class ParameterResolver extends ArgumentResolver {
  // abstract

  List<Type> requires() => [];
}

class TypeParameterResolver extends ParameterResolver {
  // instance data

  final Type type;

  // constructor

  TypeParameterResolver({required this.type});

  // override

  @override
  List<Type> requires() => [type];

  @override
  dynamic resolve(Environment environment) {
    return environment.get(type: type);
  }
}

class EnvironmentParameterResolver extends ParameterResolver {
  // constructor

  EnvironmentParameterResolver();

  // override

  @override
  dynamic resolve(Environment environment) {
    return environment;
  }
}

class Environment {
  // instance data

  Type? module;
  Environment? parent;
  final Map<Type, AbstractInstanceProvider> providers = {};
  final List<String> features;
  final List<dynamic> instances  = [];
  final List<LifecycleProcessor> lifecycleProcessors  = [];

  // constructor

  Environment({Type? forModule, this.parent, List<String>? features})  : module = forModule, features = features ?? []{
    if ( parent == null )
      if ( module == Boot) {
        lifecycleProcessors.add(OnInitCallableProcessor());
        lifecycleProcessors.add(OnInjectCallableProcessor());
        lifecycleProcessors.add(OnRunningCallableProcessor());
        lifecycleProcessors.add(OnDestroyCallableProcessor());
      }
      else parent = Boot.getEnvironment();

    final Stopwatch stopwatch = Stopwatch()..start();

    if ( Tracer.enabled )
      Tracer.trace('di', TraceLevel.low, 'create environment for module $module');

    // inherit parent providers

    if (parent != null) {
      parent!.providers.forEach((providerType, inheritedProvider) {
        var provider = inheritedProvider;
        if (inheritedProvider.scope == 'environment') {
          providers[providerType] = (inheritedProvider as EnvironmentInstanceProvider).copy(this);
        }
        else providers[providerType] = provider;
      });

      // inherit lifecycle processors

      for (final processor in parent!.lifecycleProcessors) {
        if (providers[processor.runtimeType]?.scope != 'environment') {
          lifecycleProcessors.add(processor);
        }
        else {
          get(type: processor.runtimeType); // automatically appends
        }
      }
    }
    else {
      // add bootstrap provider for Boot

      providers[SingletonScope]   = SingletonScopeInstanceProvider();
      providers[RequestScope]     = RequestScopeInstanceProvider();
      providers[EnvironmentScope] = EnvironmentScopeInstanceProvider();
    }

    final Set<TypeDescriptor> loadedModules = {};
    final List<String> prefixList = [];

    // filter by module prefix

    bool filterProvider(AbstractInstanceProvider provider) {
      final hostModule = TypeDescriptor.forType(provider.host).module;
      for (final prefix in prefixList) {
        if (hostModule.startsWith(prefix))
          return true;
      }

      return false;
    }

    // recursively load environment and its dependencies

    void loadModule(TypeDescriptor moduleDescriptor) {
      if (!loadedModules.contains(moduleDescriptor)) {
        if ( Tracer.enabled )
          Tracer.trace('di', TraceLevel.low, 'load environment $moduleDescriptor');

        loadedModules.add(moduleDescriptor);

        final decorator = moduleDescriptor.findAnnotation<Module>();
        if (decorator == null) {
          throw DIRegistrationException('$moduleDescriptor is not an module class');
        }

        // load dependencies recursively

        for (final import in  decorator.imports) {
          loadModule(TypeDescriptor.forType(import));
        }

        // Determine package prefix

        final packageName = moduleDescriptor.module;
        if (packageName.isNotEmpty) {
          prefixList.add(packageName);
        }
      }
    }

    if ( module != null) {
      loadModule(TypeDescriptor.forType(module));

      // filter providers according to prefix list

      providers.addAll(Providers.filter(this, filterProvider));

      // construct eager objects for local providers

      for (final provider in providers.values.toSet()) {
        if (provider.eager) {
          provider.create(this);
        }
      }
    } // if

    // run lifecycle callbacks

    for (final instance in instances) {
      executeProcessors(Lifecycle.onRunning, instance);
    }

    stopwatch.stop();

    if ( Tracer.enabled )
      Tracer.trace('di', TraceLevel.high, 'created environment for module $module in ${stopwatch.elapsedMilliseconds} ms, created ${instances.length} instances');
  }

  bool hasProvider(Type type) {
    return providers[type] != null;
  }

  T get<T>({Type? type}) {
    final lookup = type ?? T;
    final provider = providers[lookup];
    if (provider == null) {
      throw DIRuntimeException('$lookup is not supported');
    }

    return provider.create(this) as T;
  }

  void report() {
    for ( var provider in providers.values) {
      if ( provider is EnvironmentInstanceProvider)
        provider.printTree();
    }
  }

  bool hasFeature(String feature) {
    return features.contains(feature);
  }

  void destroy() {
    for ( var instance in instances)
      executeProcessors(Lifecycle.onDestroy, instance);

    instances.clear();
  }

  T executeProcessors<T>(Lifecycle lifecycle, T instance) {
    for ( var processor in lifecycleProcessors)
      if ( processor.lifecycle == lifecycle)
        processor.processLifecycle(instance, this);

    return instance;
  }

  T created<T>(T instance) {
    // remember lifecycle processors

    if (instance is LifecycleProcessor)
      lifecycleProcessors.add(instance);

    // sort immediately

    lifecycleProcessors.sort((a, b) => a.order.compareTo(b.order));

    // remember instance

    instances.add(instance);

    // execute processors

    executeProcessors(Lifecycle.onInject, instance);
    executeProcessors(Lifecycle.onInit, instance);

    // done

    return instance;
  }

  void initialize() {
    for (var provider in providers.values) {
      if (provider.eager) {
        provider.create(this);
      }
    }
  }

  // override Object

  @override
  String toString() => "Environment($module)";
}

abstract class AbstractInstanceProvider<T> {
  // instance data

  Type get host => runtimeType;
  Type get type;
  bool get eager;
  String get scope;

  // abstract

  (List<ParameterResolver>,Set<Type>, int) getDependencies(Environment environment) {
    return ([], {}, 1);
  }

  T create(Environment environment, [List<dynamic> args = const []]) {
     throw UnimplementedError();
  }

  void resolve(ResolveContext context){}

  String report() => toString();

  String get location => "location?";
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
  List<ParameterResolver> resolvers = [];
  AbstractScope scopeInstance;

  // constructor

  EnvironmentInstanceProvider({required this.environment, required this.provider})
      : scopeInstance = Scopes.get(provider.scope, environment);

  // public

  EnvironmentInstanceProvider copy(Environment environment) {
    var result = EnvironmentInstanceProvider(environment: environment, provider: provider);

    result.dependencies = dependencies;
    result.resolvers = resolvers;

    return result;
  }

  // internal

  void printTree([String prefix = ""]) {
    final children = dependencies!;
    final lastIndex = children.length - 1;

    print('$prefix+- ${report()}');

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final childPrefix = (i == lastIndex) ? '$prefix   ' : '$prefix|  ';
      child.printTree(childPrefix);
    }
  }

  @override
  void resolve(ResolveContext context) {
    if (dependencies == null) {
      dependencies = [];

      context.push(this);
      try {
        final (resolvers, types, params) = provider.getDependencies(environment);

        this.resolvers = resolvers;

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
    if ( Tracer.enabled)
      Tracer.trace("di", TraceLevel.full, "create ${provider.type} in $environment");

    return scopeInstance.get<T>(provider, environment,  () => ArgumentResolver.createArgs(environment, resolvers));
  }

  @override
  bool get eager => provider.eager;

  @override
  String get scope => provider.scope;

  @override
  Type get type => provider.type;

  @override
  String get location => provider.location;

  @override
  String report() => provider.report();

  // override Object

  @override
  String toString() => "EnvironmentProvider($provider)";
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

  // override

  @override
  String report() => "ambiguous: ${providers.map((provider) => provider.report()).join(',')}";

  // override Object

  @override
  String toString() => "AmbiguousProvider(${type.runtimeType})";
}

class ClassInstanceProvider<T> extends InstanceProvider<T> {
  // instance data

  final TypeDescriptor descriptor;
  List<ParameterResolver> resolvers = [];

  // constructor

  ClassInstanceProvider(Type type, {bool eager = true, String scope = 'singleton'})
      : descriptor = TypeDescriptor.forType(type), super(type: type, host: type, eager: eager, scope: scope);

  // override

  /// Returns the list of dependency types and the number of constructor parameters

  @override
  (List<ParameterResolver>,Set<Type>,int) getDependencies(Environment environment) {
    final types = <Type>{};

    // compute resolvers

    for ( var parameter in descriptor.constructorParameters) {
      var resolver = ParameterResolverFactory.createResolver(environment, parameter);

      resolvers.add(resolver);

      types.addAll(resolver.requires());
    }

    int params = descriptor.constructorParameters.length;

    // check methods annotated with @Inject, @OnInit, @OnRunning, etc.

    for ( var method in OnInitCallableProcessor.methods[host] ?? [])
      method.resolve(environment, types);

    for ( var method in OnDestroyCallableProcessor.methods[host] ?? [])
      method.resolve(environment, types);

    for ( var method in OnRunningCallableProcessor.methods[host] ?? [])
      method.resolve(environment, types);

    for ( var method in OnInjectCallableProcessor.methods[host] ?? [])
      method.resolve(environment, types);

    // done

    return (resolvers, types, params);
  }

  @override
  String get location => descriptor.location;

  /// Creates an instance of the type using the environment

  @override
  T create(Environment environment, [List<dynamic> args = const []]) {
    final instance = descriptor.fromArrayConstructor!(args);

    return environment.created(instance);
  }

  @override
  String report() => "$host(...)";

   // override Object

  @override
  String toString() => "ClassProvider($_type)";
}

/// A FunctionInstanceProvider is able to create instances of type T by calling specific methods annotated with 'create'.
class FunctionInstanceProvider<T> extends InstanceProvider<T> {
  // instance data

  final MethodDescriptor method;

  // constructor

  FunctionInstanceProvider(
      Type clazz,
      this.method, {
        bool eager = true,
        String scope = "singleton",
      }) : super(type: method.returnType, host: clazz, eager: eager, scope: scope);

  // override

  @override
  (List<ParameterResolver>, Set<Type>, int) getDependencies(Environment environment) {
    List<ParameterResolver> resolvers = [];
    Set<Type> dependencies = {};

    resolvers.add(TypeParameterResolver(type: _host));
    dependencies.add(_host);

    for ( var parameter in method.parameters) {
      var resolver = ParameterResolverFactory.createResolver(environment, parameter);

      resolvers.add(resolver);

      dependencies.addAll(resolver.requires());
    }

    return (resolvers, dependencies, method.parameters.length);
  }

  @override
  T create(Environment environment, [List<dynamic> args = const []]) {
    if ( Tracer.enabled)
      Tracer.trace("di", TraceLevel.full, "$this create class $_type");

    final instance = method.invoker!(args); // args[0] = self

    return environment.created<T>(instance);
  }

  @override
  String report() {
    final paramNames = method.parameters.map((t) => t.toString()).join(', ');
    return "${host.toString()}.${method.name}($paramNames) -> $_type";
  }

  @override
  String toString() {
    final paramNames = method.parameters.map((t) => t.toString()).join(', ');
    return "FunctionInstanceProvider($host.${method.name}($paramNames) -> $_type)";
  }
}

// boot

@Module(imports: [])
class Boot {
  static Environment? environment;

  static Environment getEnvironment() {
    // default factory for types

    TypeParameterResolverFactory();

    // add meta-data

    if (environment == null) {
      registerAllDescriptors();

      environment = Environment(forModule: Boot);
    } // if

    return environment!;
  }
}