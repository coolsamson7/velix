// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

import 'package:analyzer/dart/element/element.dart';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'package:velix/util/collections.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';

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

abstract class GeneratorElement<T extends InterfaceElement> {
  // instance data

  bool generateVariable = false;
  T element;
  List<GeneratorElement> dependencies = [];
  bool pending = true;

  // constructor

  GeneratorElement({required this.element, required TypeBuilder builder}) {
    collectImports(builder);
    collectDependencies(builder);
  }

  // internal

  void collectTypeImports(DartType type, TypeBuilder builder) {
    final element = type.element;

    // Add the type's library
    if (element?.library != null) {
      builder.addImport(element!.library!.uri);
    }

    // Handle parameterized types (e.g., List<MyClass>, Map<String, User>)
    if (type is ParameterizedType) {
      for (final typeArg in type.typeArguments) {
        collectTypeImports(typeArg, builder);
      }
    }

    // Handle function types (e.g., void Function(String))
    if (type is FunctionType) {
      // Return type
      collectTypeImports(type.returnType, builder);

      // Parameter types
      for (final param in type.formalParameters) {
        collectTypeImports(param.type, builder);
      }
    }
  }

  void collectAnnotationImports(List<ElementAnnotation> metadata, TypeBuilder builder) {
    for (final annotation in metadata) {
      final element = annotation.element;

      // Import the annotation's library
      if (element?.library != null) {
        builder.addImport(element!.library!.uri);
      }

      // Also check for types used in annotation constructor arguments
      final constantValue = annotation.computeConstantValue();
      if (constantValue != null && constantValue.type != null) {
        collectTypeImports(constantValue.type!, builder);
      }
    }
  }

  // abstract

  void generateCode(StringBuffer buffer, bool variable, TypeBuilder builder);

  // public

  void collectDependencies(TypeBuilder builder){}

  void collectImports(TypeBuilder builder) {
    builder.addImport(element.library.uri);

    collectAnnotationImports(element.metadata.annotations, builder);
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

      generateCode(buffer, generateVariable, builder);
    }
  }
}

class ClassGeneratorElement extends GeneratorElement<ClassElement> {
  static ClassCodeGenerator generator = ClassCodeGenerator();

  // instance data

  bool generateProperties;

  // constructor

  ClassGeneratorElement({required super.element, required super.builder, required this.generateProperties});

  // override

  @override
  void collectDependencies(TypeBuilder builder) {
    // super class

    final superType = element.supertype;
    if (superType != null && !superType.isDartCoreObject) {
      final superElement = superType.element;

      if (isDataclass(superElement) || isInjectable(superElement)) {
        var element = builder.checkElement(superElement, isDataclass(superElement));

        element.generateVariable = true;

        addDependency(element);
      }
    }

    // fields

    // Also collect dependencies for field types that are dataclasses
    for (final field in element.fields) {
      if (field.isStatic || field.isPrivate) continue;

      // Handle the field's direct type
      final fieldTypeElem = field.type.element3;
      if (fieldTypeElem != null &&
          fieldTypeElem is InterfaceElement &&
          fieldTypeElem != element &&
          (isDataclass(fieldTypeElem) || isInjectable(fieldTypeElem))) {
        addDependency(
            builder.checkElement(fieldTypeElem, isDataclass(fieldTypeElem)));
      }

      // Handle generic type arguments (e.g., List<MyDataclass>)
      if (field.type is ParameterizedType) {
        final paramType = field.type as ParameterizedType;
        for (final typeArg in paramType.typeArguments) {
          final typeArgElem = typeArg.element3;
          if (typeArgElem != null &&
              typeArgElem is InterfaceElement &&
              typeArgElem != element &&
              (isDataclass(typeArgElem) || isInjectable(typeArgElem))) {
            addDependency(
                builder.checkElement(typeArgElem, isDataclass(typeArgElem)));
          }
        }
      }
    }

    // Collect dependencies from method parameters and return types
    for (final method in element.methods) {
      if (!method.isPublic) continue;

      // Return type
      final returnTypeElem = method.returnType.element3;
      if (returnTypeElem != null &&
          returnTypeElem is InterfaceElement &&
          returnTypeElem != element &&
          (isDataclass(returnTypeElem) || isInjectable(returnTypeElem))) {
        addDependency(builder.checkElement(returnTypeElem, isDataclass(returnTypeElem)));
      }

      // Parameter types
      for (final param in method.formalParameters) {
        final paramTypeElem = param.type.element3;
        if (paramTypeElem != null &&
            paramTypeElem is InterfaceElement &&
            paramTypeElem != element &&
            (isDataclass(paramTypeElem) || isInjectable(paramTypeElem))) {
          addDependency(builder.checkElement(paramTypeElem, isDataclass(paramTypeElem)));
        }
      }
    }
  }

  @override
  @override
  void collectImports(TypeBuilder builder) {
    super.collectImports(builder);

    final element = this.element;

    // 1. Superclass and interfaces
    if (element.supertype != null) {
      collectTypeImports(element.supertype!, builder);
    }

    for (final interface in element.interfaces) {
      collectTypeImports(interface, builder);
    }

    for (final mixin in element.mixins) {
      collectTypeImports(mixin, builder);
    }

    // 2. Fields and their types
    for (final field in element.fields) {
      if (field.isStatic || field.isPrivate) continue;

      // Field type
      collectTypeImports(field.type, builder);

      // Field annotations
      collectAnnotationImports(field.metadata.annotations, builder);

      // Getter/setter types (accessed through the field)
      if (field.getter != null) {
        collectTypeImports(field.getter!.returnType, builder);
        collectAnnotationImports(field.getter!.metadata.annotations, builder);
      }

      if (field.setter != null) {
        for (final param in field.setter!.formalParameters) {
          collectTypeImports(param.type, builder);
          collectAnnotationImports(param.metadata.annotations, builder);
        }
        collectAnnotationImports(field.setter!.metadata.annotations, builder);
      }
    }

    // 3. Constructors and their parameters
    for (final constructor in element.constructors) {
      if (!constructor.isPublic) continue;

      // Constructor annotations
      collectAnnotationImports(constructor.metadata.annotations, builder);

      // Constructor parameters
      for (final param in constructor.formalParameters) {
        collectTypeImports(param.type, builder);
        collectAnnotationImports(param.metadata.annotations, builder);
      }
    }

    // 4. Methods, their parameters, and return types
    for (final method in element.methods) {
      if (!method.isPublic) continue;

      // Method annotations
      collectAnnotationImports(method.metadata.annotations, builder);

      // Return type
      collectTypeImports(method.returnType, builder);

      // Method parameters
      for (final param in method.formalParameters) {
        collectTypeImports(param.type, builder);
        collectAnnotationImports(param.metadata.annotations, builder);
      }

      // Type parameters (e.g., T in void myMethod<T>())
      for (final typeParam in method.typeParameters) {
        if (typeParam.bound != null) {
          collectTypeImports(typeParam.bound!, builder);
        }
      }
    }

    // 5. Class-level type parameters (e.g., T in class MyClass<T>)
    for (final typeParam in element.typeParameters) {
      if (typeParam.bound != null) {
        collectTypeImports(typeParam.bound!, builder);
      }
    }
  }

  @override
  generateCode(StringBuffer buffer, bool variable, TypeBuilder builder) {
    generator.generate(buffer, element, variable, builder, generateProperties);
  }
}

class EnumGeneratorElement extends GeneratorElement<EnumElement2> {
  static EnumCodeGenerator generator = EnumCodeGenerator();

  // constructor

  EnumGeneratorElement({required super.element, required super.builder});

  // override

  @override
  void collectImports(TypeBuilder builder) {
    super.collectImports(builder);

    final element = this.element;

    // Collect imports for enum field types (if any)
    for (final field in element.fields) {
      if (field.isStatic || field.isPrivate) continue;

      collectTypeImports(field.type, builder);
      collectAnnotationImports(field.metadata.annotations, builder);
    }

    // Collect imports for enum interfaces
    for (final interface in element.interfaces) {
      collectTypeImports(interface, builder);
    }

    // Collect imports for enum mixins
    for (final mixin in element.mixins) {
      collectTypeImports(mixin, builder);
    }
  }

  @override
  generateCode(StringBuffer buffer, bool variable, TypeBuilder builder) {
    generator.generate(buffer, element, variable, builder, false);
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

  // abstract

  void generate(StringBuffer buffer, T element, bool variable, TypeBuilder builder, bool generateProperties);
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
  void generate(StringBuffer buffer, ClassElement element, bool variable, TypeBuilder builder, bool generateProperties) {
    start(buffer);

    final className = element.name;
    final uri = element.library.uri
        .toString(); // e.g., package:example/models/foo.dart

    // i want:  package:example/models/foo.dart:1:1:Foo


    final (line, col) = builder.elementLocations[element] ?? (0, 0);

    final qualifiedName = '$uri:$line:$col';

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
  }
}

class EnumCodeGenerator extends CodeGenerator<EnumElement> {
  // override

  @override
  void generate(StringBuffer buffer, EnumElement element, bool variable, TypeBuilder builder, bool generateProperties) {
    start(buffer);

    final className = element.name;

    final uri = element.library.uri.toString(); // e.g., package:example/models/foo.dart
    final qualifiedName = '$uri.${element.name}';

    tab().writeln("enumeration<$className>(").indent(1);
    tab().writeln("name: '$qualifiedName',");

    generateAnnotations(element.metadata.annotations);

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

  Map<InterfaceElement, (int line, int column)> elementLocations = {};

  String functionName;
  String partOf;

  // constructor

  TypeBuilder({required this.functionName, required this.partOf});

  // public

  // Method to extract line/column during library processing
  Future<void> processLibraryForLocations(LibraryElement library, AssetId assetId, BuildStep buildStep) async {
    try {
      final resolver = buildStep.resolver;

      // Get the compilation unit (AST) for this specific file

      final compilationUnit = await resolver.compilationUnitFor(assetId);

      // Process each declaration in the compilation unit

      for (final declaration in compilationUnit.declarations) {
        if (declaration is ClassDeclaration) {
          final className = declaration.name.lexeme;
          // Find the corresponding ClassElement in the library
          final classElement = library.classes.where((c) => c.name == className).firstOrNull;
          if (classElement != null) {
            final lineInfo = compilationUnit.lineInfo;
            final location = lineInfo.getLocation(declaration.name.offset);
            elementLocations[classElement] = (location.lineNumber, location.columnNumber);
          }
        }
        else if (declaration is EnumDeclaration) {
          final enumName = declaration.name.lexeme;
          // Find the corresponding EnumElement in the library
          final enumElement = library.enums.where((e) => e.name == enumName).firstOrNull;
          if (enumElement != null) {
            final lineInfo = compilationUnit.lineInfo;
            final location = lineInfo.getLocation(declaration.name.offset);
            elementLocations[enumElement] = (location.lineNumber, location.columnNumber);
          }
        }
      }
    }
    catch (e) {
      // If we can't get locations, they'll remain (0, 0)
      print('Error getting locations for ${assetId.path}: $e');
    }
  }

  @override
  final buildExtensions = const {
    //r'$lib$': ['type_registry.g.dart']
    '.dart': ['.type_registry.g.dart']
  };

  // internal

  void addImport(Uri value) {
    imports.add(value);
  }

  GeneratorElement checkElement(InterfaceElement element, bool generateProperties) {
    var result = visited[element];

    if ( result == null) {
      if (element is ClassElement)
        elements.add(result = ClassGeneratorElement(element: element, builder: this, generateProperties: generateProperties));
      else if (element is EnumElement)
        elements.add(result = EnumGeneratorElement(element: element, builder: this));

      visited[element] = result!;
    } // if

    return result;
  }

  // header

  void generateHeader(StringBuffer buffer) {
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: unnecessary_import');

    if (partOf.isNotEmpty)
      buffer.writeln("part of '$partOf';");
    else {
      buffer.writeln("import 'package:velix/velix.dart';");
      buffer.writeln("import 'package:velix_di/velix_di.dart';");
    }
  }

  // write imports

  void generateImports(StringBuffer buffer) {
    for (final sourceUri in imports) {
      if (sourceUri.scheme == 'asset') {
        // join all segments
        var relativePath = sourceUri.pathSegments.join('/');

        // remove leading 'package_name/test/' if present
        final testIndex = relativePath.indexOf('/test/');
        if (testIndex != -1) {
          // everything after 'test/' becomes the import path
          relativePath = relativePath.substring(testIndex + '/test/'.length);
        }

        buffer.writeln("import '$relativePath';");
      }
      else {
        buffer.writeln("import '$sourceUri';");
      }
    }
  }

  // traverse all elements

  void generate(StringBuffer buffer) {
    buffer.writeln();
    buffer.writeln('void $functionName() {');

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

      await processLibraryForLocations(library, input, buildStep);

      final annotatedClasses = library.classes.where((cls) {
        return cls.metadata.annotations.any((annotation) {
          final name = annotation.element?.enclosingElement?.name;

          return name == 'Dataclass' ||
              name == 'Injectable' ||
              name == 'Module' ||
              name == 'Scope';
        });
      }).toList();

      for (final element in annotatedClasses) {
        checkElement(element, hasAnnotation(element, "Dataclass"));
      } // for
    }

    // generate code

    final buffer = StringBuffer();

    generateHeader(buffer);
    if ( partOf.isEmpty)
      generateImports(buffer);

    generate(buffer);

    final fileName = p.basenameWithoutExtension(buildStep.inputId.path);

    // Write to type_registry.g.dart

    final assetId = AssetId(buildStep.inputId.package, '$dir/$fileName.type_registry.g.dart');

    await buildStep.writeAsString(assetId, buffer.toString());
  }
}

Builder typeBuilder(BuilderOptions options) {
  final config = options.config;

  final functionName = config['function_name'] as String? ?? 'registerAllDescriptors';
  final partOf = config['part_of'] as String? ?? "";

  return TypeBuilder(functionName: functionName, partOf: partOf);
}
