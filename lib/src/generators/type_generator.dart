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

DartType? extractElementDartType(FieldElement field) {
  final type = field.type;
  if (type is ParameterizedType) {
    if (type.element?.name == 'List' && type.typeArguments.isNotEmpty) {
      return type.typeArguments.first;
    }
  }

  return null;
}


class AggregateBuilder implements Builder {
  // Outputs a fixed file in /lib; adjust as needed.

  @override
  final buildExtensions = const {
    //r'$lib$': ['type_registry.g.dart']
    '.dart': ['.type_registry.g.dart']
  };

  // internal

  String generateClass(ClassElement element) {
    final className = element.name;
    final buffer = StringBuffer();

    final uri = element.source.uri.toString(); // e.g., package:example/models/foo.dart

    final qualifiedName = '$uri.${element.name}';

    buffer.writeln("   type<$className>(");
    buffer.writeln("     name: '$qualifiedName',");

    buffer.write("     params: ");

    // collect parameters

    for (final ctor in element.constructors) {
      if (!ctor.isFactory && ctor.isPublic) {
        buffer.writeln("[");

        for (final param in ctor.parameters) {
          final name = param.name;
          final typeStr = param.type.getDisplayString();
          final isNamed = param.isNamed;
          final isRequired = param.isRequiredNamed || param.isRequiredPositional;
          final isNullable = param.isOptional || param.isOptionalNamed;
          final defaultValue = param.defaultValueCode ?? "null";

          buffer.write("         param<$typeStr>('$name'");

          if (isNamed)
            buffer.write(", isNamed: $isNamed");

          if (isRequired)
            buffer.write(", isRequired: $isRequired");

          if (isNullable)
            buffer.write(", isNullable: $isNullable");

          if ( !isRequired)
            buffer.write(", defaultValue: $defaultValue");

          buffer.writeln("),");
        }

        buffer.writeln("       ],");
      }
    }

    // For constructor function: keep generating for the first public constructor (or you can customize)

    final firstCtor = findElement(element.constructors, (c) => !c.isFactory && c.isPublic);

    // write constructor function

    if (firstCtor == null) {
      buffer.writeln("     constructor: () => throw UnsupportedError('No public constructor'),");
    }
    else {
      buffer.write("     constructor: ({");

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

      buffer.write(paramsStr);

      buffer.write("}) => $className(");

      // Pass parameters to actual constructor, named if necessary

      final args = <String>[];
      for (final param in firstCtor.parameters) {
        if (param.isNamed) {
          args.add("${param.name}: ${param.name}");
        }
        else {
          args.add(param.name);
        }
      }

      buffer.write(args.join(", "));
      buffer.writeln("),");
    }

    buffer.writeln("     fields: [");

    for (final field in element.fields) {
      if (field.isStatic || field.isPrivate) continue;

      final name = field.name;
      final type = field.type.getDisplayString();

      //print('${field.name} → ${field.type} → ${field.type.nullabilitySuffix}');

      final isFinal = field.isFinal;
      final isNullable = isTypeNullable(field.type);

      String typeCode = extractAttributeTypeFromField(field);

      final elementType = extractElementDartType(field);

      buffer.writeln("         field<$className,$type>('$name',");

      if ( typeCode.contains("."))
        buffer.writeln("           type: $typeCode,");

      if (elementType != null) {
        final elementTypeName = elementType.getDisplayString();
        buffer.writeln("           elementType: $elementTypeName,");
        buffer.writeln("           factoryConstructor: () => <$elementTypeName>[],");
      }

      buffer.writeln("           getter: (obj) => (obj as $className).$name,");

      if ( !isFinal) {
        buffer.writeln("           setter: (obj, value) => (obj as $className).$name = value,");
      }
      else {
        buffer.writeln("           isFinal: $isFinal,");
      }

      if ( isNullable )
        buffer.writeln("           isNullable: true");

      buffer.writeln('         ),');
    }

    buffer.writeln("       ]");
    buffer.writeln("     );");

    return buffer.toString();
  }

  String extractAttributeTypeFromField(FieldElement field) {
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

  // override

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    final classes = <ClassElement>[];

    final isTestFile = buildStep.inputId.toString().contains('|test/');
    var dir = isTestFile ? "test" : "lib";

    // Find all Dart files in lib/

    await for (final input in buildStep.findAssets(Glob('$dir/**.dart'))) {
      final library = await resolver.libraryFor(input, allowSyntaxErrors: true);
      for (final element in LibraryReader(library).annotatedWith(TypeChecker.fromRuntime(Dataclass))) {
        if (element.element is ClassElement) {
          classes.add(element.element as ClassElement);
        }
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln("import 'package:velix/velix.dart';");

    final seenImports = <Uri>{};
    for (final clazz in classes) {
      final sourceUri = clazz.source.uri;

      if (seenImports.add(sourceUri)) {
          if (sourceUri.scheme == 'asset')
            buffer.writeln("import '${sourceUri.pathSegments.last}';");
          else
            buffer.writeln("import '$sourceUri';");
      } // if
    }

    buffer.writeln();

    buffer.writeln('void registerAllDescriptors() {');

    for (final clazz in classes) {
      buffer.writeln(generateClass(clazz));
    }

    buffer.writeln('}');

    final fileName = p.basenameWithoutExtension(buildStep.inputId.path);

    // Write to type_registry.g.dart

    final assetId = AssetId(buildStep.inputId.package, '$dir/$fileName.type_registry.g.dart');
    await buildStep.writeAsString(assetId, buffer.toString());
  }
}

Builder typeBuilder(BuilderOptions options) => AggregateBuilder();
