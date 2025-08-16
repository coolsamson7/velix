import 'dart:async';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';

import '../../util/collections.dart';


bool isTypeNullable(DartType type) {
  return type.nullabilitySuffix == NullabilitySuffix.question;
}

bool isDataclass(Element element) {
  return element.metadata.any((annotation) {
    final value = annotation.computeConstantValue();
    if (value == null)
      return false;

    return value.type?.getDisplayString() == 'Dataclass';
  });
}

abstract class GeneratorElement<T extends InterfaceElement> {
  // instance data

  T element;
  List<GeneratorElement> dependencies = [];
  bool pending = true;

  // constructor

  GeneratorElement({required this.element, required TypeBuilder builder}) {
    collectImports(builder);
    collectDependencies(builder);
  }

  // internal

  void collectAnnotationImports(List<ElementAnnotation> metadata, TypeBuilder builder) {
    for (final annotation in metadata) {
      final libUri = annotation.element?.library?.source.uri;
      if (libUri != null) {
        builder.addImport(libUri);
      }
    }
  }

  // abstract

  generateCode(StringBuffer buffer);

  collectDependencies(TypeBuilder builder){}

  // public

  collectImports(TypeBuilder builder) {
    builder.addImport(element.source.uri);

    collectAnnotationImports(element.metadata, builder);
  }

  void addDependency(GeneratorElement element) {
    dependencies.add(element);
  }

  void generate(TypeBuilder builder, StringBuffer buffer) {
    if ( pending ) {
      pending = false;

      // recursion

      for ( var dependency in dependencies)
        dependency.generate(builder, buffer);

      // generate

      generateCode(buffer);
    }
  }
}

class ClassGeneratorElement extends GeneratorElement<ClassElement> {
  static ClassCodeGenerator generator = ClassCodeGenerator();

  // instance data

  // constructor

  ClassGeneratorElement({required super.element, required super.builder});

  // override

  @override
  void collectDependencies(TypeBuilder builder) {
    // super class

    final superType = element.supertype;
    if (superType != null && !superType.isDartCoreObject) {
      final superElement = superType.element;

      if (superElement != null && isDataclass(superElement)) {
        addDependency(builder.checkElement(superElement));
      }
    }

    // fields

    for (final field in element.fields) {
      if (field.isStatic)
        continue;

      final fieldTypeElem = field.type.element;
      if (fieldTypeElem != null && fieldTypeElem is InterfaceElement && fieldTypeElem != element && isDataclass(fieldTypeElem)) {
        addDependency(builder.checkElement(fieldTypeElem));
      }
    } // for
  }

  @override
  collectImports(TypeBuilder builder) {
    super.collectImports(builder);

    for (final field in element.fields) {
      collectAnnotationImports(field.metadata, builder);
    }
  }

  @override
  generateCode(StringBuffer buffer) {
    generator.generate(buffer, element);
  }
}

class EnumGeneratorElement extends GeneratorElement<EnumElement> {
  static EnumCodeGenerator generator = EnumCodeGenerator();

  // constructor

  EnumGeneratorElement({required super.element, required super.builder});

  // override

  @override
  generateCode(StringBuffer buffer) {
    generator.generate(buffer, element);
  }
}

abstract class CodeGenerator<T extends InterfaceElement> {
  // instance data

  StringBuffer buffer = StringBuffer();
  int level = 0;

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

  void generateAnnotations(Element element) {
    var annotations = readAnnotations(element.metadata);

    if ( annotations.isNotEmpty ) {
      tab().writeln("annotations: [").indent(1);

      for (final annotation in annotations) {
        tab().write(annotation.substring(1)).writeln(",");
      }

      indent(-1).tab().writeln("],");
    }
  }

  // abstract

  void generate(StringBuffer buffer, T element);
}

class ClassCodeGenerator extends CodeGenerator<ClassElement> {
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

      if (superElement != null && isDataclass(superElement)) {
        return superElement.name;
      }
    }

    return null;
  }

  String fieldType(FieldElement field) {
    var typeName =  field.type.getDisplayString();

    AbstractType? constraint = switch (typeName) {
      "String" => StringType(),
      "int" => IntType(),
      "double" => DoubleType(),
      "bool" => BoolType(),
      _ => null
    };

    if ( constraint != null) {
      for (final annotation in field.metadata) {
        final constant = annotation.computeConstantValue();
        if (constant == null) continue;

        final type = constant.type;
        if (type != null &&
            type.getDisplayString() == 'Attribute') {
          final typeValue = constant.getField('type');
          if (typeValue != null && typeValue.toStringValue() != "") {
            constraint.constraint(typeValue.toStringValue()!);
          }
        }
      }

      return constraint.code();
    }
    else {
      if (typeName.endsWith("?"))
        typeName = typeName.substring(0, typeName.length - 1);

      if ( typeName.startsWith("List<")) {
        return "ListType($typeName)";
      }
      else
        return "ObjectType($typeName)";
    }
  }

  void generateConstructorParams(ClassElement element) {
    tab().write("params: ");

    // collect parameters

    for (final ctor in element.constructors) {
      if (!ctor.isFactory && ctor.isPublic) {
        writeln("[").indent(1);

        for (final param in ctor.parameters) {
          final name = param.name;
          final typeStr = param.type.getDisplayString();
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

          if ( !isRequired)
            write(", defaultValue: $defaultValue");

          writeln("),");
        }

        indent(-1).tab().writeln("],");
      }
    }
  }

  void generateField(String className, FieldElement field) {
    final name = field.name;
    final type = field.type.getDisplayString(withNullability: false);

    final isFinal = field.isFinal;
    final isNullable = isTypeNullable(field.type);

    String typeCode = fieldType(field);

    tab().writeln("field<$className,$type>('$name',").indent(1);

    if ( typeCode.contains("."))
      tab().writeln("type: $typeCode,");

    generateAnnotations(field);

    final elementType = getElementType(field);
    if (elementType != null) {
      final elementTypeName = elementType.getDisplayString();

      tab().writeln("elementType: $elementTypeName,");
      tab().writeln("factoryConstructor: () => <$elementTypeName>[],");
    }

    tab().writeln("getter: (obj) => (obj as $className).$name,");

    if ( !isFinal) {
      tab().writeln("setter: (obj, value) => (obj as $className).$name = value,");
    }
    else {
      tab().writeln("isFinal: $isFinal,");
    }

    if ( isNullable )
      tab().writeln("isNullable: true");

    indent(-1).tab().writeln('),');
  }

  void generateFields(ClassElement element) {
    tab().writeln("fields: [").indent(1);

    for (final field in element.fields) {
      if (field.isStatic || field.isPrivate)
        continue;

      generateField(element.name, field);
    } // for

    indent(-1).tab().writeln("]");
  }

  void generateConstructor(ClassElement element) {
    // For constructor function: keep generating for the first public constructor (or you can customize)

    final firstCtor = findElement(element.constructors, (c) => !c.isFactory && c.isPublic);

    // write constructor function

    if (firstCtor == null) {
      tab().writeln("constructor: () => throw UnsupportedError('No public constructor'),");
    }
    else {
      tab().write("constructor: ({");

      final paramsBuffer = StringBuffer();

      for (final param in firstCtor.parameters) {
        var paramType = param.type.getDisplayString();
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
      }

      // Remove trailing comma and space, if any

      var paramsStr = paramsBuffer.toString().trimRight();
      if (paramsStr.endsWith(',')) {
        paramsStr = paramsStr.substring(0, paramsStr.length - 1);
      }

      write(paramsStr).write("}) => ${element.name}(");

      // Pass parameters to actual constructor, named if necessary

      final positionalArgs = <String>[];
      final namedArgs = <String>[];

      for (final param in firstCtor.parameters) {
        if (param.isNamed) {
          namedArgs.add("${param.name}: ${param.name}");
        }
        else {
          positionalArgs.add(param.name);
        }
      }

    // Combine positional first (no names), then named (with names)

      final args = <String>[]
        ..addAll(positionalArgs)
        ..addAll(namedArgs);

      write(args.join(", ")).writeln("),");
    }
  }

  // override

  @override
  void generate(StringBuffer buffer, ClassElement element) {
    start(buffer);

    final className = element.name;
    final uri = element.source.uri.toString(); // e.g., package:example/models/foo.dart
    final qualifiedName = '$uri.${element.name}';

    tab().write("var ${className}Descriptor = ").writeln("type<$className>(").indent(1);
    tab().writeln("name: '$qualifiedName',");

    var superClass = getSuperclass(element);
    if ( superClass != null) {
      tab().writeln("superClass: '${superClass}Descriptor',");
    }

    generateAnnotations(element);
    generateConstructorParams(element);
    generateConstructor(element);
    generateFields(element);

    indent(-1).tab().writeln(");");
  }
}

class EnumCodeGenerator extends CodeGenerator<EnumElement> {
  // override

  @override
  void generate(StringBuffer buffer, EnumElement element) {
    start(buffer);

    final className = element.name;

    final uri = element.source.uri.toString(); // e.g., package:example/models/foo.dart
    final qualifiedName = '$uri.${element.name}';

    tab().writeln("enumeration<$className>(").indent(1);
    tab().writeln("name: '$qualifiedName',");

    generateAnnotations(element);

    tab().writeln("values: $className.values");
    indent(-1).tab().writeln(");");
  }
}

class TypeBuilder implements Builder {
  // instance data

  Map<InterfaceElement,GeneratorElement> visited = {};
  List<GeneratorElement> elements = [];
  Set<Uri> imports = <Uri>{};

  // Outputs a fixed file in /lib; adjust as needed.

  @override
  final buildExtensions = const {
    //r'$lib$': ['type_registry.g.dart']
    '.dart': ['.type_registry.g.dart']
  };

  // internal

  void addImport(Uri value) {
    imports.add(value);
  }

  GeneratorElement checkElement(InterfaceElement element) {
    var result = visited[element];

    if ( result == null) {
      if (element is ClassElement)
        elements.add(result = ClassGeneratorElement(element: element, builder: this));
      else if (element is EnumElement)
        elements.add(result = EnumGeneratorElement(element: element, builder: this));

      visited[element] = result!;
    } // if

    return result!;
  }

  // header

  void generateHeader(StringBuffer buffer) {
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln("import 'package:velix/velix.dart';");
  }

  // write imports

  void generateImports(StringBuffer buffer) {
    for (final sourceUri in imports) {
      if (sourceUri.scheme == 'asset')
        buffer.writeln("import '${sourceUri.pathSegments.last}';");
      else
        buffer.writeln("import '$sourceUri';");
    }
  }

  // traverse all elements

  void generate(StringBuffer buffer) {
    buffer.writeln();
    buffer.writeln('void registerAllDescriptors() {');

    bool first = true;
    for ( var element in elements) {
      if (!first)
        buffer.writeln();

      element.generate(this, buffer);

      first = false;
    }

    buffer.writeln('}');
  }

  // override

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;

    final isTestFile = buildStep.inputId.toString().contains('|test/');
    var dir = isTestFile ? "test" : "lib";

    // Find all Dart files in lib/

    await for (final input in buildStep.findAssets(Glob('$dir/**.dart'))) {
      final library = await resolver.libraryFor(input, allowSyntaxErrors: true);
      for (final element in LibraryReader(library).annotatedWith(TypeChecker.fromRuntime(Dataclass))) {
        if ( element.element is InterfaceElement)
          checkElement(element.element as InterfaceElement);
      } // for
    }

    // generate code

    final buffer = StringBuffer();

    generateHeader(buffer);
    generateImports(buffer);
    generate(buffer);

    final fileName = p.basenameWithoutExtension(buildStep.inputId.path);

    // Write to type_registry.g.dart

    final assetId = AssetId(buildStep.inputId.package, '$dir/$fileName.type_registry.g.dart');

    await buildStep.writeAsString(assetId, buffer.toString());
  }
}

Builder typeBuilder(BuilderOptions options) => TypeBuilder();
