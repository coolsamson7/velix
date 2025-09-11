import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../../util/collections.dart';
import '../../validation/validation.dart';

String assetIdToImportUri(AssetId id) { // TODO test
  if (id.path.startsWith('lib/')) {
    final relative = id.path.substring(4);
    return 'package:${id.package}/$relative';
  }
  else if (id.path.startsWith('test/')) {
    final relative = id.path;
    return 'asset:${id.package}/$relative';
  }
  return 'asset:${id.package}/${id.path}';
}

typedef FetchCode = Future<String> Function(String name, List<int> offset);
typedef FindNode = Element Function(String ref);

String? returnTypeUri(MethodElement method) {
  final DartType returnType = method.returnType;

  // Only class/interface types have a library
  if (returnType is InterfaceType) {
    final classElement = returnType.element;
    return "${classElement.library.uri}:${classElement.name}";
  }

  // e.g. void, dynamic, function types, etc. → no class
  return null;
}

bool isTypeNullable(DartType type) {
  return type.nullabilitySuffix == NullabilitySuffix.question;
}

bool isDataclass(InterfaceElement element) {
  return element.metadata.annotations.any((annotation) {
    final value = annotation.computeConstantValue();
    if (value == null)
      return false;

    return value.type?.getDisplayString() == 'Dataclass';
  });
}

bool isInjectable(InterfaceElement element) {
  return element.metadata.annotations.any((annotation) {
    final value = annotation.computeConstantValue();
    if (value == null)
      return false;

    return value.type?.getDisplayString() == 'Injectable';
  });
}

bool hasAnnotation(ClassElement element, String annotationName) {
  return element.metadata.annotations.any((annotation) {
    final value = annotation.computeConstantValue();
    if (value == null) return false;

    return value.type?.getDisplayString() == annotationName;
  });
}

abstract class CodeGenerator<T extends InterfaceElement> {
  // instance data

  StringBuffer buffer = StringBuffer();
  int level = 0;

  // constructor

  CodeGenerator();

  // protected

  void start(StringBuffer buffer) {
    this.buffer = buffer;
    level = 1;
  }

  CodeGenerator<T> indent(int delta) {
    level += delta;

    return this;
  }

  CodeGenerator<T>  tab() {
    for ( int i = 0; i < level; i++)
      buffer.write("  ");

    return this;
  }

  CodeGenerator<T> write(String code) {
    buffer.write(code);

    return this;
  }

  CodeGenerator<T> writeln(String code) {
    buffer.writeln(code);

    return this;
  }

  /// Reads raw annotation source and collects import URIs for annotation libraries.
  List<String> readAnnotations(List<ElementAnnotation> metadata) {
    final result = <String>[];
    for (final annotation in metadata) {
      var source = annotation.toSource();
      if (!source.startsWith("@Dataclass") && ! source.startsWith("@Attribute"))
        result.add(source); // exact source text
    }

    return result;
  }

  void generateAnnotations(List<ElementAnnotation> elementAnnotations) {
    var annotations = readAnnotations(elementAnnotations);

    if ( annotations.isNotEmpty ) {
      tab().writeln("annotations: [").indent(1);

      int len = annotations.length;
      int i = 0;
      for (final annotation in annotations) {
        tab().write(annotation.substring(1)).writeln(i < len-1 ? "," : "");

        i++;
      }

      indent(-1).tab().writeln("],");
    }
  }

  Set<Uri> imports = <Uri>{};
  Set<String> dependencies = <String>{};

  void addImport(Uri import) {
    imports.add(import);
  }

  void collectImports(T element) {
    addImport(element.library.uri);

    collectAnnotationImports(element.metadata.annotations);
  }

  void addDependency(String dependency) {
    if ( !dependency.startsWith("dart:"))
      dependencies.add(dependency);
  }

  void collectDependencies(T element) {
    //addDependency(element.library.uri);
  }

  void collectAnnotationImports(List<ElementAnnotation> metadata) {
    for (final annotation in metadata) {
      final libUri = annotation.element?.library?.uri;
      if (libUri != null) {
        addImport(libUri);
      }
    }
  }

  // abstract

  Map<String,dynamic> generate(StringBuffer buffer, T element,  AssetId assetId, CharacterLocation location);
}

class EnumCodeGenerator extends CodeGenerator<EnumElement> {
  // instance data

  final bool variable;

  // constructor

  EnumCodeGenerator({required this.variable});

  // override

  @override
  Map<String, dynamic> generate(StringBuffer buffer, EnumElement element, AssetId assetId, CharacterLocation location) {
    collectDependencies(element);
    collectImports(element);

    this.start(buffer);

    int start = buffer.length;

    final className = element.name;

    final uri = element.library.uri.toString(); // e.g., package:example/models/foo.dart
    final qualifiedName = '$uri.${element.name}';

    tab().writeln("enumeration<$className>(").indent(1);
    tab().writeln("name: '$qualifiedName',");

    generateAnnotations(element.metadata.annotations);

    tab().writeln("values: $className.values");
    indent(-1).tab().writeln(");");

    return {
      'name': "${assetIdToImportUri(assetId)}:${element.name}",
      'type': element.name,
      'dependencies': dependencies.toList(),
      'offset': [start, buffer.length],
      'imports': imports.map((uri) => uri.toString()).toList(),
    };
  }
}

class ClassCodeGenerator extends CodeGenerator<ClassElement> {
  // instance data

  final bool variable;
  final bool generateProperties;

  // constructor

  ClassCodeGenerator({required this.variable, required this.generateProperties});

  // override

  @override
  void collectDependencies(ClassElement element) {
    super.collectDependencies(element);

    // super class

    final superType = element.supertype;
    if (superType != null && !superType.isDartCoreObject) {
      final superElement = superType.element;

      if (isDataclass(superElement) || isInjectable(superElement)) {
        addDependency("${superType.element.library.uri}:${superElement.name}");
      }
    } // if
  }

  @override
  void collectImports(ClassElement element) {
    super.collectImports(element);

    if ( generateProperties )
      for (final field in element.fields) {
        collectAnnotationImports(field.metadata.annotations);
      }
  }

  // internal

  DartType? getElementType(FieldElement field) {
    final type = field.type;
    if (type is ParameterizedType) {
      if (type.element?.name == 'List' && type.typeArguments.isNotEmpty) {
        return type.typeArguments.first;
      }
    }

    return null;
  }

  String? getSuperclass(ClassElement element) {
    // super class

    final superType = element.supertype;
    if (superType != null && !superType.isDartCoreObject) {
      final superElement = superType.element;

      if (isDataclass(superElement) || isInjectable(superElement)) {
        return superElement.name;
      }
    }

    return null;
  }

  String fieldType(FieldElement field) {
    var nullable = false;
    var typeName =  field.type.getDisplayString();

    if (typeName.endsWith("?")) {
      typeName = typeName.substring(0, typeName.length - 1);
      nullable = true;
    }

    AbstractType? constraint = switch (typeName) {
      "DateTime" => DateTimeType(),
      "String" => StringType(),
      "int" => IntType(),
      "double" => DoubleType(),
      "bool" => BoolType(),
      _ => null
    };

    // literal types

    if ( constraint != null) {
      // add optional

      if ( nullable) {
        constraint = (constraint as dynamic).optional();
      }

      // add constraints

      for (final annotation in field.metadata.annotations) {
        final constant = annotation.computeConstantValue();
        if (constant == null) continue;

        final type = constant.type;
        if (type != null &&
            type.getDisplayString() == 'Attribute') {
          final typeValue = constant.getField('type');
          if (typeValue != null && typeValue.toStringValue() != "") {
            (constraint as dynamic).constraint(typeValue.toStringValue()!);
          }
        }
      }

      return  (constraint as dynamic).code();
    }
    else {
      if ( typeName.startsWith("List<")) {
        return "ListType($typeName)";
      }
      else
        return "ObjectType($typeName)";
    }
  }

  //

  void generateMethods(ClassElement element) {
    final methods = element.methods.where((method) =>
        method.metadata.annotations.any((annotation) {
          final value = annotation.computeConstantValue();
          if (value == null)
            return false;
          final typeName = value.type?.getDisplayString();
          return typeName == 'OnInit' || typeName == 'OnDestroy' || typeName == 'OnRunning' || typeName == 'Create' || typeName == 'Inject';
        })
    ).toList();

    if (methods.isEmpty)
      return;

    tab().writeln("methods: [").indent(1);

    int len = methods.length;
    int i = 0;
    for (final method in methods) {
      generateMethod(element.name!, method, i == len - 1);
      i++;
    }

    indent(-1).tab().writeln("],");
  }

  void generateParameters(List<FormalParameterElement> parameters) {
    tab().writeln("parameters: [").indent(1);
    int i = 0;
    int len = parameters.length;

    for ( var param in parameters) {
      final name = param.name;
      final typeStr = param.type.getDisplayString(withNullability: false);
      final isNamed = param.isNamed;
      final isRequired = param.isRequiredNamed || param.isRequiredPositional;
      final isNullable = param.isOptional || param.isOptionalNamed;
      final defaultValue = param.defaultValueCode ?? "null";

      tab().write("param<$typeStr>('$name'");

      if (isNamed)
        write(", isNamed: $isNamed");

      if (isRequired)
        write(", isRequired: $isRequired");

      if (isNullable)
        write(", isNullable: $isNullable");

      if (!isRequired)
        write(", defaultValue: $defaultValue");

      if (param.metadata.annotations.isNotEmpty) {
        writeln(",").tab();
        generateAnnotations(param.metadata.annotations);
      }

      write(")").writeln(i < len - 1 ? ", " : "");

      i++;
    }

    indent(-1).tab().writeln("],");
  }

  void generateMethod(String className, MethodElement method, bool last) {
    final methodName = method.name;
    final returnType = method.returnType;
    final isAsync = method.returnType.isDartAsyncFuture;

    // Find the lifecycle annotation

    for (final annotation in method.metadata.annotations) {
      final value = annotation.computeConstantValue();
      if (value != null) {
        final typeName = value.type?.getDisplayString();
        if (typeName == 'OnInit' || typeName == 'OnDestroy' ||  typeName == 'Create') {
          break;
        }
      }
    }
    
    //addDependency(returnTypeUri(method)!);

    tab().writeln("method<$className,$returnType>('$methodName',").indent(1);

    generateAnnotations(method.metadata.annotations);
    if (method.formalParameters.isNotEmpty) generateParameters(method.formalParameters);

    if (isAsync)
      tab().writeln("isAsync: $isAsync,");

    tab().write("invoker: (List<dynamic> args)");

    if (isAsync) {
      write("async ");
    }

    write("=> ");
    write("(args[0] as $className).$methodName(");

    // Generate parameter passing for injection methods
    if (method.formalParameters.isNotEmpty) {
      for (int i = 0; i < method.formalParameters.length; i++) {
        var parameter =  method.formalParameters[i];

        if (i > 0)
          write(", ");

        if ( parameter.isNamed)
          write(parameter.displayName).write(": ");

        write("args[${i + 1}]");
      }
    }

    write(")");
    writeln("");

    indent(-1).tab().write(')').writeln(last ? "" : ", ");
  }

  //

  void generateConstructorParams(ClassElement element) {
    // collect parameters

    for (final ctor in element.constructors) {
      if (!ctor.isFactory && ctor.isPublic) {
        int len = ctor.formalParameters.length;

        if (len > 0) {
          tab().write("params: ");

          writeln("[").indent(1);

          int i = 0;
          for (final param in ctor.formalParameters) {
            final name = param.name;
            final typeStr = param.type.getDisplayString(withNullability: false);
            final isNamed = param.isNamed;
            final isRequired = param.isRequiredNamed ||
                param.isRequiredPositional;
            final isNullable = param.isOptional || param.isOptionalNamed;
            final defaultValue = param.defaultValueCode ?? "null";

            var uri = param.type.element?.library?.uri;

           addDependency("${uri}:${param.type.name}");

            tab().write("param<$typeStr>('$name'");

            if (isNamed)
              write(", isNamed: $isNamed");

            if (isRequired)
              write(", isRequired: $isRequired");

            if (isNullable)
              write(", isNullable: $isNullable");

            if (!isRequired)
              write(", defaultValue: $defaultValue");

            if (param.metadata.annotations.isNotEmpty) {
              writeln(",").tab();
              generateAnnotations(param.metadata.annotations);
            }

            write(")").writeln(i < len - 1 ? ", " : "");

            i++;
          }

          indent(-1).tab().writeln("],");
        }
      }
    }
  }

  void generateField(String className, FieldElement field, bool last) {
    final name = field.name3;
    final type = field.type.getDisplayString(withNullability: false);

    final isFinal = field.isFinal;
    final isNullable = isTypeNullable(field.type);

    String typeCode = fieldType(field);

    tab().writeln("field<$className,$type>('$name',").indent(1);

    if ( typeCode.contains("."))
      tab().writeln("type: $typeCode,");

    generateAnnotations(field.metadata.annotations);

    final elementType = getElementType(field);
    if (elementType != null) {
      final elementTypeName = elementType.getDisplayString(withNullability: false);

      tab().writeln("elementType: $elementTypeName,");
      tab().writeln("factoryConstructor: () => <$elementTypeName>[],");
    }

    tab().writeln("getter: (obj) => obj.$name,"); // (obj as $className).$name

    if ( !isFinal) {
      tab().writeln("setter: (obj, value) => (obj as $className).$name = value,");
    }
    //else {
    //  tab().writeln("isFinal: $isFinal,");
    //}

    if ( isNullable )
      tab().writeln("isNullable: true");

    indent(-1).tab().write(')').writeln(last ? "" : ", ");
  }

  void generateFields(ClassElement element) {
    tab().writeln("fields: [").indent(1);

    int len = element.fields.length;
    int i = 0;
    for (final field in element.fields) {
      if (!field.isStatic && !field.isPrivate)
        generateField(element.name!, field, i == len - 1);

      i++;
    } // for

    indent(-1).tab().writeln("]");
  }

  void generateFromMapConstructor(ClassElement element) {
    // For constructor function: keep generating for the first public constructor (or you can customize)

    final firstCtor = findElement(element.constructors, (c) => !c.isFactory && c.isPublic);

    // write constructor function

    if (firstCtor == null) {
      tab().writeln("//fromMapConstructor: () => throw UnsupportedError('No public constructor'),");
    }
    else {
      tab().write("fromMapConstructor: (Map<String,dynamic> args) => ${element.name}(");

      bool first = true;
      for (final param in firstCtor.formalParameters) {
        if ( !first )
          write(", ");
        else
          first = false;

        var paramType = param.type.getDisplayString(withNullability: false);
        final paramName = param.name;

        if ( param.isPositional) {
          write("args['$paramName'] as $paramType");
        }
        else if ( param.isNamed) {
          write("$paramName: args['$paramName'] as $paramType");

          // Use param.defaultValueCode or default literal for some common types if null

          String? defaultValue = param.defaultValueCode;
          if (defaultValue == null) {
            if (paramType == 'String') {
              defaultValue = "''";
            }
            else if (paramType == 'int') {
              defaultValue = "0";
            }
            else if (paramType == 'double') {
              defaultValue = "0.0";
            }
            else if (paramType == 'bool') {
              defaultValue = "false";
            }
            else if (paramType.endsWith('?')) {
              // nullable type
              defaultValue = "null";
            }
            else {
              defaultValue = "NULL"; // fallback
            }
          }

          if (defaultValue != "NULL") {
            if ( defaultValue == "null")
              write("? ?? null");
            else
              write("? ?? $defaultValue");
          }
        }


      }

      writeln("),");
    }
  }

  void generateFromArrayConstructor(ClassElement element) {
    // For constructor function: keep generating for the first public constructor (or you can customize)

    final firstCtor = findElement(element.constructors, (c) => !c.isFactory && c.isPublic);

    // write constructor function

    if (firstCtor == null) {
      tab().writeln("fromArrayConstructor: () => throw UnsupportedError('No public constructor'),");
    }
    else {
      tab().write("fromArrayConstructor: (List<dynamic> args) => ${element.name}(");

      bool first = true;
      int index = 0;
      for (final param in firstCtor.formalParameters) {
        if ( !first )
          write(", ");
        else
          first = false;

        var paramType = param.type.getDisplayString(withNullability: false);
        final paramName = param.name;

        if ( param.isPositional) {
          write("args[$index] as $paramType");
        }
        else if ( param.isNamed) {
          write("$paramName: args[$index] as $paramType");

          // Use param.defaultValueCode or default literal for some common types if null

          String? defaultValue = param.defaultValueCode;
          if (defaultValue == null) {
            if (paramType == 'String') {
              defaultValue = "''";
            }
            else if (paramType == 'int') {
              defaultValue = "0";
            }
            else if (paramType == 'double') {
              defaultValue = "0.0";
            }
            else if (paramType == 'bool') {
              defaultValue = "false";
            }
            else if (paramType.endsWith('?')) {
              // nullable type
              defaultValue = "null";
            }
            else {
              defaultValue = "NULL"; // fallback
            }
          }

          if (defaultValue != "NULL") {
            if ( defaultValue == "null")
              write("? ?? null");
            else
              write("? ?? $defaultValue");
          }
        }

        // next

        index += 1;
      } // for

      writeln("),");
    }
  }

  void generateConstructor(ClassElement element) {
    // For constructor function: keep generating for the first public constructor (or you can customize)

    final firstCtor = findElement(element.constructors, (c) => !c.isFactory && c.isPublic);

    // write constructor function

    if (firstCtor == null) {
      tab().writeln("constructor: () => throw UnsupportedError('No public constructor'),");
    }
    else {
      tab().write("constructor: (");

      if ( firstCtor.formalParameters.isNotEmpty)
        write("{");

      final paramsBuffer = StringBuffer();

      for (final param in firstCtor.formalParameters) {
        var paramType = param.type.getDisplayString(withNullability: false);
        final paramName = param.name;

        // Use param.defaultValueCode or default literal for some common types if null

        String? defaultValue = param.defaultValueCode;
        if (defaultValue == null) {
          if (paramType == 'String') {
            defaultValue = "''";
          }
          else if (paramType == 'int') {
            defaultValue = "0";
          }
          else if (paramType == 'double') {
            defaultValue = "0.0";
          }
          else if (paramType == 'bool') {
            defaultValue = "false";
          }
          else if (paramType.endsWith('?')) {
            // nullable type
            defaultValue = "null";
          }
          else {
            defaultValue = "NULL"; // fallback
          }
        }

        if (defaultValue == "NULL")
          paramsBuffer.write("required $paramType $paramName, ");
        else {
          if ( defaultValue == "null")
            paramsBuffer.write("$paramType $paramName, ");
          else
            paramsBuffer.write("$paramType $paramName = $defaultValue, ");
        }
      } // for

      // Remove trailing comma and space, if any

      var paramsStr = paramsBuffer.toString().trimRight();
      if (paramsStr.endsWith(',')) {
        paramsStr = paramsStr.substring(0, paramsStr.length - 1);
      }

      write(paramsStr);
      if ( paramsStr.isNotEmpty)
        write("}");

      write(") => ${element.name}(");

      // Pass parameters to actual constructor, named if necessary

      final positionalArgs = <String>[];
      final namedArgs = <String>[];

      for (final param in firstCtor.formalParameters) {
        if (param.isNamed) {
          namedArgs.add("${param.name}: ${param.name}");
        }
        else {
          positionalArgs.add(param.name!);
        }
      }

      // Combine positional first (no names), then named (with names)

      final args = <String>[...positionalArgs, ...namedArgs];

      write(args.join(", ")).writeln("),");
    } // else
  }

  // override

  @override
  Map<String,dynamic> generate(StringBuffer buffer, ClassElement element, AssetId assetId, CharacterLocation location) {
    collectDependencies(element);
    collectImports(element);

    this.start(buffer);

    int start = buffer.length;

    // write code

    final className = element.name;
    final uri = element.library.uri
        .toString(); // e.g., package:example/models/foo.dart

    // i want:  package:example/models/foo.dart:1:1:Foo

    final qualifiedName = '$uri:${location.lineNumber}:${location.columnNumber}';

    tab();
    if (variable)
      write("var ${className}Descriptor = ");

    writeln("type<$className>(").indent(1);
    tab().writeln("location: '$qualifiedName',");

    var superClass = getSuperclass(element);
    if (superClass != null) {
      tab().writeln("superClass: ${superClass}Descriptor,");
    }

    if (element.metadata.annotations.isNotEmpty) {
      //writeln(",").tab();
      generateAnnotations(element.metadata.annotations);
    }

    if (!element.isAbstract) {
      generateConstructorParams(element);
      generateConstructor(element);
      //generateFromMapConstructor(element); make it configurable?
      generateFromArrayConstructor(element);
    }
    else tab().writeln("isAbstract: true,");

    if ( generateProperties && element.fields.isNotEmpty)
      generateFields(element);

    generateMethods(element);

    indent(-1).tab().writeln(");");

    // return meta data

    return {
      'name': "${assetIdToImportUri(assetId)}:${element.name}",
      //'file': assetId.package,
      //"path": assetId.path,
      'type': element.name,
      'dependencies': this.dependencies.toList(),
      'offset': [start, buffer.length],
      'imports': imports.map((uri) => uri.toString()).toList(),
    };
  }
}

class FragmentBuilder extends Builder {
  // instance data

  @override
  final buildExtensions = const {
    '.dart': ['.registry.json', '.registry.dart']
  };

  // override

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final path = buildStep.inputId.path;

    // Skip generated or irrelevant files
    if (!path.endsWith('.dart') ||
        path.contains('.g.dart') ||
        path.contains('.part.dart') ||
        path.contains('.freezed.dart') ||
        path.contains('.gr.dart') ||
        path.contains('combined_registry.dart')) {
      return;
    }

    try {
      final lib = await buildStep.resolver.libraryFor(buildStep.inputId);

      // Get parsed AST to resolve line/col

      final session = lib.session;
      final parsedLib = await session.getParsedLibraryByElement(lib) as ParsedLibraryResult;
      final unit = parsedLib.units.first.unit;
      final lineInfo = parsedLib.units.first.lineInfo;

      final List<Map<String,dynamic>> classes =[];
      final buffer = StringBuffer();

      // scan all classes

      bool handle(InterfaceElement e) {
        return e.metadata.annotations.any((a) {
          final name = a.element?.enclosingElement?.name;
          return name == 'Dataclass' || name == 'Injectable' || name == 'Module' || name == 'Scope';
        });
      }

      // scan all classes

      for (final cls in [...lib.classes, ...lib.enums].where(handle)) {
        // Find AST node for line/col

        var location = CharacterLocation(-1, -1);
        try {
          final node = unit.declarations
              .whereType<ClassDeclaration>()
              .firstWhere(
                (d) => d.name.lexeme == cls.name,
            orElse: () => throw Exception('Class node not found'),
          );

          location = lineInfo.getLocation(node.offset);
        }
        catch(e) {
          print("no node for $cls");
        }

        if ( cls is EnumElement) {
          classes.add(EnumCodeGenerator(variable: false).generate(buffer, cls, buildStep.inputId, location));
        }
        else if ( cls is ClassElement)
          classes.add(ClassCodeGenerator(variable: false, generateProperties: false).generate(buffer, cls, buildStep.inputId, location));
      }

      // write JSON metadata

      if (classes.isNotEmpty) {
        final jsonOut = buildStep.inputId.changeExtension('.registry.json');
        await buildStep.writeAsString(
          jsonOut,
          const JsonEncoder.withIndent('  ').convert({'classes': classes}),
        );
      }

      // write code fragment

      if (buffer.isNotEmpty) {
        final codeOut = buildStep.inputId.changeExtension('.registry.dart');

        await buildStep.writeAsString(codeOut, buffer.toString());
      }
    }
    catch (e, stackTrace) {
      log.warning('Skipping $path: $e');
      log.fine('$stackTrace');
    }
  }
}

class Element {
  // instance data

  bool resolved = false;

  final String name;
  final String type;
  final List<String> imports;
  final List<String> dependencies;
  final List<Element> dependants = [];
  final List<int> offset;
  int inDegree = 0;

  // constructor

  Element(
      {required this.name, required this.type, required this.imports, required this.dependencies, required this.offset}) {
    inDegree = dependencies.length;
  }

  // public

  Future<void> emit(StringBuffer buffer, bool variable, FindNode find,
      FetchCode fetch) async {
    if (dependants.isNotEmpty) {
      var colon = name.lastIndexOf(":");
      var className = name.substring(colon + 1);

      buffer.write("var ${className}Descriptor = ");
    }

    // emit

    buffer.write(await fetch(name, offset));
  }
}


class RegistryAggregator extends Builder {
  // instance data

  String functionName;
  String partOf;


  @override
  final buildExtensions = const {'.dart': ['.registry.g.dart']};

  // constructor

  RegistryAggregator({required this.functionName, required this.partOf});

  // override

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    log.info('🚀 CombinedRegistryAggregator triggered by: ${buildStep.inputId.path}');

    final rootPackage = buildStep.inputId.package;
    final mainFileName = buildStep.inputId.pathSegments.last;

    try {
      final allJsonAssets = await buildStep
          .findAssets(Glob('**/*.registry.json'))
          .where((id) => id.package == rootPackage)
          .toList();

      // sort, so we stay stable

      allJsonAssets.sort((a,b) => a.path.compareTo(b.path));

      // TODO

      final List<AssetId> allRegistryAssets = await buildStep
          .findAssets(Glob('**/*.registry.dart'))
          .where((id) => id.package == rootPackage)
          .toList();

      print(allRegistryAssets);

      final Map<AssetId, String> assets = HashMap<AssetId, String>();

      Future<String> getAsset(AssetId assetId) async {
        var result = assets[assetId];

        if (result == null) {
          result =  await buildStep. readAsString(assetId);
          assets[assetId] = result;
        }

        return result;
      }


      /// Converts a "package:..." URI string into an AssetId
      (String, String) packagePath(String packageUri) {
        // TODO test
        if (packageUri.startsWith("asset:")) {
          // Remove asset: prefix
          final assetPart = packageUri.substring('asset:'.length);
          // Split into package and path
          final slash = assetPart.indexOf('/');
          final package = assetPart.substring(0, slash); // 'velix_di'
          // Find the part before the colon (:)
          final colon = assetPart.lastIndexOf(':');
          final filePath = assetPart.substring(
              slash + 1, colon); // 'test/conflict/conflict.dart'
          final fragmentPath = filePath.replaceAll(
              RegExp(r'\.dart$'), '.registry.dart');

          return (package, filePath);
        }

        if (!packageUri.startsWith('package:')) {
          throw ArgumentError('Expected a package URI, got: $packageUri');
        }
        final withoutPrefix = packageUri.substring('package:'.length);
        final parts = withoutPrefix.split('/');
        final package = parts.first;
        final path = parts.skip(1).join('/');
        return (package, path);
      }

      Future<String> getCode(String name, List<int> offset) async {
        var (package, path) = packagePath(name);

        if ( path.contains(":"))
          path = path.substring(0, path.lastIndexOf(":"));

        var fragmentPath = path.replaceAll(RegExp(r'\.dart$'), '.registry.dart');
        if ( !fragmentPath.startsWith("test"))
          fragmentPath = "lib/$fragmentPath";

        var code = await getAsset(AssetId(package, fragmentPath)); // TODO test

        return code.substring(offset[0], offset[1]);
      }

      // Load metadata for sorting and dependency resolution

      final Map<String, Element> elements = {};
      for (final assetId in allJsonAssets) {
        try {
          final content = await buildStep.readAsString(assetId);

          final Map<String, dynamic> data = json.decode(content);

          final List<dynamic> classes = data['classes'];

          // create and remember wrapper classes

          for ( var cl in classes)
            elements[cl["name"]] = Element(
                name: cl["name"],
                type: cl["type"],
                dependencies: (cl["dependencies"] as List<dynamic>).cast<String>(),
                imports: (cl["imports"] as List<dynamic>).cast<String>(),
                offset: (cl["offset"] as List<dynamic>).cast<int>(),
            );
        }
        catch (e) {
          log.warning('Could not read JSON ${assetId.path}: $e');
        }
      }

      Element findElement(String ref) { // "sample:/lib/foo.dart:Foo"
        return elements[ref]!;
      }

      // resolve elements

      for (final element in elements.values) {
        for ( var dependency in element.dependencies) {

          findElement(dependency).dependants.add(element);
        }
      }

      // Combine all code fragments

      final buffer = StringBuffer()
        ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
        ..writeln('// Generated by velix registry builder')
        ..writeln();

      // gather imports from metadata

      final importSet = <String>{};

      String getImport(String import) {
        if (import.startsWith('asset:')) { // asset:velix_di/test/bla...
          // join all segments
          var index = import.indexOf("/test");

          import = import.substring(index + "/test/".length);
        }

        return import;
      }

      for (final element in elements.values) {
        importSet.addAll(element.imports);
      }

      // and print

      if (partOf != "")
        buffer
          ..writeln("part of '$partOf';")
          ..writeln();
      else {
        for (final importPath in importSet.toList()
          ..sort()) {
          buffer.writeln("import '${getImport(importPath)}';");
        }
      }

      buffer.writeln();

      buffer.writeln('void registerAll() {');
      if (elements.isEmpty) {
        buffer.writeln('  // No annotated classes found');
      }
      else {
        //for (final element in elements.values) {
        //  await element.emit(buffer, false, findElement, getCode);
        //}

        // start with elements with inDegree == 0

        final List<Element> queue = [
          for (var element in elements.values)
            if (element.inDegree == 0) element,
        ];

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);

          await current.emit(buffer, false, findElement, getCode);

          for (var dep in current.dependants) {
            dep.inDegree--;
            if (dep.inDegree == 0)
              queue.add(dep);
          } // for
        } // while
      }

      buffer.writeln('}');

      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, buffer.toString());

      log.info('✅ Successfully generated part file');
    }
    catch (e, stackTrace) {
      log.severe('❌ Error in CombinedRegistryAggregator: $e');
      log.fine('$stackTrace');
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, _generateEmptyPartFile(mainFileName));
    }
  }

  String _generateEmptyPartFile(String mainFileName) => '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated by velix registry builder


void $functionName() {
}
''';
}

/// ----------------------------
/// Builder factories
/// ----------------------------

Builder registryPerFileBuilder(BuilderOptions options) =>  FragmentBuilder();

Builder combinedRegistryAggregator(BuilderOptions options) {
  final config = options.config;

  final functionName = config['function_name'] as String? ?? 'registerAllDescriptors';
  final partOf = config['part_of'] as String? ?? "";

  return RegistryAggregator(functionName: functionName, partOf: partOf);
}
