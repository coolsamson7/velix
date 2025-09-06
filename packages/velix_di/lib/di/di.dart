import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/util/tracer.dart';

// annotations

/// Abstract base class for conditions
mixin Condition {
  bool applies(Environment environment);
}

/// Condition that checks for a specific feature
class feature with Condition {
  final String _feature;

  /// create a new [feature]
  /// [_feature] the required feature
  const feature(this._feature);

  @override
  bool applies(Environment environment) {
    return environment.hasFeature(_feature);
  }
}

/// this annotation is ued to define specific requirements for the appropriate class
/// to be managed by an environment
class Conditional extends ClassAnnotation {
  final Condition requires;

  // constructor

  /// Create a new [Conditional]
  /// [requires] required condition
  const Conditional({required this.requires});

  // override

  @override
  void apply(TypeDescriptor type) {

  }
}

/// Classes, annotated with [Injectable] are able to be managed by an environment
/// This is also an indicator for the code-generator to emit the meta-data.
class Injectable extends ClassAnnotation {
  final bool eager;
  final String scope;
  final bool factory;
  final bool replace;

  // constructor

  const Injectable({this.factory = true, this.eager = true, this.replace = false, this.scope = 'singleton'});

  // override

  @override
  void apply(TypeDescriptor type) {
    if (factory && !type.isAbstract)
      Providers.register(ClassInstanceProvider(type.type, eager: eager, scope: scope, replace: replace));
  }
}

/// Methods annotated with [Create] are factories for the return type.
/// [eager] if [true], thg instance wil be created automatically. This is the default
/// [scope] tge scope. Default tis "singleton"
class Create extends MethodAnnotation {
  final bool eager;
  final String scope;
  final bool replace;

  const Create({this.eager = true, this.replace = false, this.scope = "singleton"});

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    Providers.register(FunctionInstanceProvider(type.type, method, eager: eager, scope: scope, replace: replace));
  }
}

/// Classes annotated with  [Module] determine, which classes are managed by it.
/// The rule is that all classes inside or under the library of this class are eligible.
class Module extends ClassAnnotation {
  final List<Type> imports;
  final bool includeSubdirectories;
  final bool includeSiblings;

  // constructor

  /// Create a new [Module]
  /// [imports] possible list of modules which will be recursively imported.
  const Module({List<Type>? imports, this.includeSubdirectories = true, this.includeSiblings = true}) : imports = imports ?? const [];

  // override

  @override
  void apply(TypeDescriptor type) {
    Providers.register(ClassInstanceProvider(type.type, eager: true));
  }
}

/// Methods annotated with  [OnInit] are executed after constructor invocation and all injections.
/// Methods can declare any injectable parameters
class OnInit extends MethodAnnotation {
  const OnInit();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    AbstractLifecycleMethodProcessor.register(type, Lifecycle.onInit, method);
  }
}

/// Methods annotated with  [OnRunning] are executed after constructor of all eager environment objects
/// Methods can declare any injectable parameters
class OnRunning extends MethodAnnotation {
  const OnRunning();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    AbstractLifecycleMethodProcessor.register(type, Lifecycle.onRunning, method);
  }
}

/// Methods annotated with  [Inject] are executed after constructor invocation.
/// Methods can declare any injectable parameters
class Inject extends MethodAnnotation {
  const Inject();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    AbstractLifecycleMethodProcessor.register(type, Lifecycle.onInject, method);
  }
}

/// Methods annotated with  [OnDestroy] are executed after environment destruction.
/// Methods can declare any injectable parameters
class OnDestroy extends MethodAnnotation {
  const OnDestroy();

  // override

  @override
  void apply(TypeDescriptor type, MethodDescriptor method) {
    AbstractLifecycleMethodProcessor.register(type, Lifecycle.onDestroy, method);
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

  void processLifecycle(InstanceProvider? provider, dynamic instance, Environment environment);
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

 abstract class AbstractLifecycleMethodProcessor extends LifecycleProcessor {
   // static data

   static Map<Type, List<List<MethodCall>>> methods = {};
   static Map<Type, List<List<MethodCall>>> allMethods = {}; // including inherited

   // static methods

   static void register(TypeDescriptor type, Lifecycle lifecycle, MethodDescriptor method) {
     methods.putIfAbsent(type.type, () => [for (int i = 0; i < 4; i++) []])[lifecycle.index].add(MethodCall(method: method));
   }

   static void resolve(Environment environment, InstanceProvider provider, TypeDescriptor type, Set<Type> types) {
     // make sure that i inherit superclass methods!

     List<MethodCall> methodList = [];

     // local methods

     Iterable<T> iterate<T>(List<T> list, {bool reverse = false}) {
       return reverse ? list.reversed : list;
     }

     void addMethod(Type type, MethodCall method, int lifecycle, bool reverse) {
       var list = allMethods.putIfAbsent(type, () => [for (int i = 0; i < 4; i++) []])[lifecycle];

       if ( reverse )
         list.insert(0, method);
       else
         list.add(method);

       methodList.add(method);
     }

     List<List<MethodCall>> inheritMethods(TypeDescriptor t) {
       var result = allMethods[t.type];

       if ( result != null )
         return result; // done

       result = allMethods[t.type] = [[], [], [], []];

       // super class

       if ( t.superClass != null ) {
         // recursion

         var inherited = inheritMethods(t.superClass!);

         for (int lifecycle = 0; lifecycle < 4; lifecycle++) {
           var reverse = lifecycle == 3;

           for (var method in iterate(inherited[lifecycle], reverse: reverse)) {
             addMethod(t.type, method, lifecycle, reverse);
           }
         }
       } // if

       // add own methods

       for (int lifecycle = 0; lifecycle < 4; lifecycle++) {
         var reverse = lifecycle == 3;

         for (MethodCall method in methods[t.type]?[lifecycle] ?? []) {
           addMethod(t.type, method, lifecycle, reverse); // methodList.add(method); //  was
         }
       }

       // done

       return result;
     } // inheritMethods

     // make sure, methods are inherited

     inheritMethods(type);

     // resolve matching methods

     for ( var method in methodList )
       method.resolve(environment, types);

     // store in provider

     provider.lifecycleMethods = allMethods[type.type]!;

     //for ( int i = 0; i < 4; i++)
     //  if (provider.lifecycleMethods[i]!.isEmpty)
      //   provider.lifecycleMethods[i] = null;
   }

   // instance data

   bool reverse = false;

   // constructor

   AbstractLifecycleMethodProcessor({required super.lifecycle, this.reverse = false});

   // override

   @override
   // TODO: implement order
   int get order => 1;

   void execute(List<MethodCall>? methods, instance, environment) {
     if ( methods != null)
       for (var method in methods)
         method.execute(instance, environment);
   }

   @override
   void processLifecycle(InstanceProvider? provider, instance, Environment environment) {
     // TODO
     //var methods = provider.lifecycleMethods[lifecycle.index];
     //if ( methods != null)
     //  execute(methods[lifecycle.index], instance, environment);

     execute(allMethods[instance.runtimeType]![lifecycle.index], instance, environment);
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
  void processLifecycle(InstanceProvider? provider, instance, Environment environment) {
    process(instance, environment);
  }
}

@Injectable(eager: false)
class OnInjectProcessor extends AbstractLifecycleMethodProcessor {
  OnInjectProcessor() :super(lifecycle: Lifecycle.onInject);
}

@Injectable(eager: false)
class OnInitProcessor extends AbstractLifecycleMethodProcessor {
  OnInitProcessor() :super(lifecycle: Lifecycle.onInit);
}

@Injectable(eager: false)
class OnRunningProcessor extends AbstractLifecycleMethodProcessor {
  OnRunningProcessor() :super(lifecycle: Lifecycle.onRunning);
}

@Injectable(eager: false)
class OnDestroyProcessor extends AbstractLifecycleMethodProcessor {
  OnDestroyProcessor() :super(lifecycle: Lifecycle.onDestroy, reverse: true);
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

      var descriptor = TypeDescriptor.forType(provider.type);

      Conditional? conditional = descriptor.getAnnotation<Conditional>();
      if ( conditional != null) {
        if (!conditional.requires.applies(environment))
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
            if ( provider.replace)
              cache[type] = provider;
            else
              existingProvider.addProvider(provider);
          }
          else {
            if ( existingProvider.replace && provider.replace)
              cache[type] = AmbiguousProvider(type: type, providers: [existingProvider, provider]);
            else if (existingProvider.replace) {
              cache[type] = existingProvider;
            }
            else if (provider.replace) {
              cache[type] = provider;
            }
            else {
              cache[type] = AmbiguousProvider(type: type, providers: [existingProvider, provider]);
            }
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
    if ( !factories.contains(factory))
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

  // internal

  bool isLiteralType(ParameterDescriptor parameter) {
    if ( parameter.type == int ||  parameter.type == double  ||  parameter.type == String ||  parameter.type == bool)
      return true;

    return false;
  }

  // override

  @override
  bool applies(Environment environment, ParameterDescriptor parameter) {
    return !isLiteralType(parameter); // ?? environment.hasProvider(parameter.type);
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

/// This is the DI container which is responsible for the lifecycle of its managed classes
/// // and offers the main API to retrieve objects via the `get<T>` method.
class Environment {
  // instance data

  Type? module;
  Environment? parent;
  final Map<Type, AbstractInstanceProvider> providers = {};
  final List<String> features;
  final List<dynamic> instances  = [];
  final List<List<LifecycleProcessor>> lifecycleProcessors  = [[], [], [], []];

  // constructor

  /// Create a new [Environment]
  /// [forModule] the module class that determines the classes which will be manged
  /// [parent] optional parent environment, whose objects will be inherited
  /// [features] list of feature that this environment defines. See [Conditional]
  Environment({Type? forModule, this.parent, List<String>? features})  : module = forModule, features = features ?? []{
    if ( parent == null )
      if ( module == Boot) {
        lifecycleProcessors[0].add(OnInjectProcessor());
        lifecycleProcessors[1].add(OnInitProcessor());
        lifecycleProcessors[2].add(OnRunningProcessor());
        lifecycleProcessors[3].add(OnDestroyProcessor());
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

      for (int lifecycle = 0; lifecycle < 4; lifecycle++)
        for (final processor in parent!.lifecycleProcessors[lifecycle]) {
          if (providers[processor.runtimeType]?.scope != 'environment') {
            lifecycleProcessors[lifecycle].add(processor);
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
    final List<RegExp> filter = [];

    // filter by module prefix

    bool filterProvider(AbstractInstanceProvider provider) {
      final hostModule = TypeDescriptor.forType(provider.host).module;

      //print("filter $provider");
      for (final fileFilter in filter) {
        if (fileFilter.hasMatch(hostModule)) {
          //print("ok");
          return true;
        }
      }

      //print("na");
      return false;
    }

    RegExp buildModuleRegex(String modulePath, {bool includeChildren = false, bool includeSiblings = false}) {
      final lastSlash = modulePath.lastIndexOf('/');
      final dir = lastSlash >= 0 ? modulePath.substring(0, lastSlash) : '';
      final fileOrDir = lastSlash >= 0 ? modulePath.substring(lastSlash + 1) : modulePath;

      String pattern;

      if (!includeChildren && !includeSiblings) {
        // Only the file itself
        pattern = '^' + RegExp.escape(modulePath) + r'$';
      }
      else if (includeSiblings && !includeChildren) {
        // All siblings in the same directory
        pattern = '^' + RegExp.escape(dir) + r'/[^/]+$';
      }
      else if (!includeSiblings && includeChildren) {
        // If the modulePath is a directory (ends with no file), match files/dirs inside it (direct children)
        // If modulePath is a file, match direct children of its directory and recurse further.
        if (fileOrDir.contains('.')) {
          // modulePath is a file, include children means all files and dirs inside its directory recursively
          pattern = '^' + RegExp.escape(dir) + r'/.*$';
        }
        else {
          // modulePath is a directory, include children means direct children of that directory
          pattern = '^' + RegExp.escape(modulePath) + r'/[^/]+$';
        }
      }
      else {
        // Both siblings and children
        if (fileOrDir.contains('.')) {
          // If path is a file, siblings + children means siblings of file + any descendants inside directory
          pattern = '^' + RegExp.escape(dir) + r'/([^/]+|.*)$';
        }
        else {
          // If path is directory, siblings + children means direct children and directory itself's siblings
          pattern = '^' + RegExp.escape(dir) + r'/([^/]+|.*)$';
        }
      }

      //print("$modulePath, includeChildren: $includeChildren, includeSiblings: $includeSiblings -> $pattern");

      return RegExp(pattern);
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

        // determine package prefix

        final module = moduleDescriptor.getAnnotation<Module>()!;

        final packageName = moduleDescriptor.module;
        if (packageName.isNotEmpty) {
          filter.add(buildModuleRegex(packageName, includeChildren: module.includeSubdirectories, includeSiblings: module.includeSiblings));
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
      executeProcessors(null, Lifecycle.onRunning, instance);
    }

    stopwatch.stop();

    if ( Tracer.enabled )
      Tracer.trace('di', TraceLevel.high, 'created environment for module $module in ${stopwatch.elapsedMilliseconds} ms, created ${instances.length} instances');
  }

  bool hasProvider(Type type) {
    return providers[type] != null;
  }

  ///return an object given the desired type
  /// [T] the generic type
  /// [type] optional type for calls where a generic type is not available
  T get<T>({Type? type}) {
    final lookup = type ?? T;
    final provider = providers[lookup];
    if (provider == null) {
      throw DIRuntimeException('$lookup is not supported');
    }

    return provider.create(this) as T;
  }

  /// print a report on the console showing the providers and their dependencies
  void report() {
    for ( var provider in providers.values) {
      if ( provider is EnvironmentInstanceProvider)
        provider.printTree();
    }
  }

  bool hasFeature(String feature) {
    return features.contains(feature);
  }

  /// destroy the environment invoking all [OnDestroy] callbacks.
  void destroy() {
    for ( var instance in instances)
      executeProcessors(null, Lifecycle.onDestroy, instance);

    instances.clear();
  }

  T executeProcessors<T>(InstanceProvider? provider, Lifecycle lifecycle, T instance) {
    for ( var processor in lifecycleProcessors[lifecycle.index])
        processor.processLifecycle(provider, instance, this);

    return instance;
  }

  T created<T>(InstanceProvider provider, T instance) {
    // remember lifecycle processors

    if (instance is LifecycleProcessor) {
      lifecycleProcessors[instance.lifecycle.index].add(instance);

      // sort immediately

      lifecycleProcessors[instance.lifecycle.index].sort((a, b) => a.order.compareTo(b.order));
    }

    // remember instance

    instances.add(instance);

    // execute processors

    executeProcessors(provider, Lifecycle.onInject, instance);
    executeProcessors(provider, Lifecycle.onInit, instance);

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

/// internal class that is able to provide a specific type.
abstract class AbstractInstanceProvider<T> {
  // instance data

  Type get host => runtimeType;
  Type get type;
  bool get eager;
  bool get replace;
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
  final bool replace;

  List<List<MethodCall>?> lifecycleMethods = [];

  // constructor

  InstanceProvider({required Type type, Type? host, bool eager = true, this.replace = false, String scope = "singleton"})
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

  @override
  bool get replace => false;
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
  T create(Environment environment, [List<dynamic> args = const []]) {
    throw DIRuntimeException("ambiguous providers for $_type");
  }

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

  ClassInstanceProvider(Type type, {bool eager = true, replace = false, String scope = 'singleton'})
      : descriptor = TypeDescriptor.forType(type), super(type: type, host: type, eager: eager, scope: scope, replace: replace);

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

    AbstractLifecycleMethodProcessor.resolve(environment, this, TypeDescriptor.forType(host), types);

    // done

    return (resolvers, types, params);
  }

  @override
  String get location => descriptor.location.replaceFirst("asset:", "package:");

  /// Creates an instance of the type using the environment

  @override
  T create(Environment environment, [List<dynamic> args = const []]) {
    final instance = descriptor.fromArrayConstructor!(args);

    return environment.created(this, instance);
  }

  @override
  String report() {
    StringBuffer buffer = StringBuffer("$_type: $location ");

    return buffer.toString();
  }

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
        bool replace = false,
        String scope = "singleton",
      }) : super(type: method.returnType, host: clazz, eager: eager, scope: scope, replace: replace);

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

    // inherit lifecycle methods

    AbstractLifecycleMethodProcessor.resolve(environment, this, TypeDescriptor.forType(_type), dependencies);

    // done

    return (resolvers, dependencies, method.parameters.length);
  }

  @override
  T create(Environment environment, [List<dynamic> args = const []]) {
    if ( Tracer.enabled)
      Tracer.trace("di", TraceLevel.full, "$this create class $_type");

    final instance = method.invoker!(args); // args[0] = self

    return environment.created<T>(this, instance);
  }

  @override
  String report() {
    //final paramNames = method.parameters.map((t) => t.toString()).join(', ');

    return "$_type: ${host.toString()}.${method.name} (${method.typeDescriptor.location}) "; // paramNames
  }

  @override
  String toString() {
    final paramNames = method.parameters.map((t) => t.toString()).join(', ');
    return "FunctionInstanceProvider($host.${method.name}($paramNames) -> $_type)";
  }
}

// boot

@Module()
class Boot {
  static Environment? environment;

  static Environment getEnvironment() {
    environment ??= Environment(forModule: Boot);

    return environment!;
  }
}