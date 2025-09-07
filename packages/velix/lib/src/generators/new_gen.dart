import 'dart:async';
import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// ----------------------------
/// Per-class builder
/// ----------------------------
class RegistryPerFileBuilder extends Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.registry.json', '.registry.dart'] // Both JSON metadata AND code fragments
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // Skip non-Dart files and generated files
    if (!buildStep.inputId.path.endsWith('.dart') ||
        buildStep.inputId.path.contains('.g.dart') ||
        buildStep.inputId.path.contains('.part.dart') ||
        buildStep.inputId.path.contains('.freezed.dart') ||
        buildStep.inputId.path.contains('.gr.dart') ||
        buildStep.inputId.path.contains('combined_registry.dart')) {
      return;
    }

    try {
      final lib = await buildStep.resolver.libraryFor(buildStep.inputId);

      // Check if this is actually a library (not a part file)
      //if (lib.source.uri.toString().contains('part of')) {
      //  log.fine('Skipping part file: ${buildStep.inputId.path}');
      //  return; // Skip part files
      //}

      final classesWithDataclass = <Map<String, dynamic>>[];
      final codeFragments = <String>[];
      final imports = <String>{};

      for (final cls in lib.classes) {
        var isDataclass = false;
        for (final annotation in cls.metadata.annotations) {
          final obj = annotation.computeConstantValue();
          if (obj?.type?.getDisplayString(withNullability: false) == 'Dataclass') {
            isDataclass = true;
            break;
          }
        }
        if (!isDataclass) continue;

        final typeName = cls.name;
        final superClass = cls.supertype?.getDisplayString(withNullability: false) ?? 'Object';

        // Extract constructor dependencies
        final dependencies = <String>[];
        /*try {
          final constructor = cls.constructors.firstWhere(
                (c) => c.name.isEmpty, // Default constructor
            orElse: () => cls.constructors.isNotEmpty ? cls.constructors.first : null,
          );

          if (constructor != null) {
            for (final param in constructor.parameters) {
              final paramType = param.type.getDisplayString(withNullability: false);
              if (paramType != 'dynamic' && paramType != 'Object') {
                dependencies.add(paramType);
              }
            }
          }
        } catch (e) {
          log.warning('Could not extract constructor info for $typeName: $e');
        }*/

        // JSON metadata for sorting
        final meta = {
          'type': typeName,
          'superClass': superClass,
          'dependencies': dependencies,
          'sourceFile': buildStep.inputId.path,
          'variableName': '${typeName}Type', // Variable name for references
        };
        classesWithDataclass.add(meta);

        // Add import for this class
        imports.add(_getImportPath(buildStep.inputId.path));

        // Generate code fragment for this class
        final codeFragment = _generateClassRegistrationCode(
          typeName!,
          superClass,
          dependencies,
          cls, // Pass the class element for additional introspection
        );

        codeFragments.add(codeFragment);
      }

      // Write JSON metadata (for dependency sorting)
      if (classesWithDataclass.isNotEmpty) {
        final jsonOut = buildStep.inputId.changeExtension('.registry.json');
        await buildStep.writeAsString(
            jsonOut,
            const JsonEncoder.withIndent('  ').convert({
              'classes': classesWithDataclass,
            })
        );
      }

      // Write code fragments
      if (codeFragments.isNotEmpty) {
        final codeOut = buildStep.inputId.changeExtension('.registry.dart');
        final buffer = StringBuffer();

        // Add imports section
        buffer.writeln('// REGISTRY FRAGMENT - DO NOT EDIT');
        for (final import in imports) {
          buffer.writeln("import '$import';");
        }
        buffer.writeln();

        // Add all code fragments
        for (final fragment in codeFragments) {
          buffer.writeln(fragment);
          buffer.writeln();
        }

        await buildStep.writeAsString(codeOut, buffer.toString());
      }

    } catch (e, stackTrace) {
      // Log and skip files that can't be processed as libraries
      log.warning('Skipping ${buildStep.inputId.path}: $e');
      log.fine('Stack trace: $stackTrace');
      return;
    }
  }

  String _getImportPath(String sourceFile) {
    if (sourceFile.startsWith('lib/')) {
      return sourceFile.substring(4);
    }
    return sourceFile;
  }

  String _generateClassRegistrationCode(
      String typeName,
      String superClass,
      List<String> dependencies,
      ClassElement cls,
      ) {
    final buffer = StringBuffer();
    final variableName = '${typeName.toLowerCase()}Type';

    // Generate the registration code fragment with variable declaration
    buffer.writeln('// Registration for $typeName');
    buffer.write('final $variableName = type<$typeName>(');

    final params = <String>[];

    // Note: superClass and dependencies will be resolved by variable names in the combiner
    if (superClass != 'Object') {
      params.add('/* superClass will be resolved */');
    }

    if (dependencies.isNotEmpty) {
      params.add('/* dependencies will be resolved */');
    }

    // TODO: You can add more introspection here:
    // - Extract properties: cls.fields
    // - Extract constructor args: cls.constructors.first.parameters
    // - Add metadata, annotations, etc.

    buffer.write(params.join(', '));
    buffer.write(');');

    return buffer.toString();
  }
}

/// ----------------------------
/// Aggregator builder
/// ----------------------------
/// ----------------------------
/// Aggregator builder (Trigger File Version)
/// ----------------------------
class CombinedRegistryAggregator extends Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.registry.g.dart']  // Generate .g.dart part file
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // Only run when triggered by a specific main file that will include the part
    //if (!buildStep.inputId.path.endsWith('lib/registry.dart')) {  // or whatever your main file is called
    //  return; // Skip all other files
    //}

    print("#### CombinedRegistryAggregator generating part file");

    log.info('🚀 CombinedRegistryAggregator triggered by: ${buildStep.inputId.path}');

    final rootPackage = buildStep.inputId.package;
    final mainFileName = buildStep.inputId.pathSegments.last; // e.g., 'registry.dart'

    try {
      // Collect JSON metadata files for dependency sorting
      final allJsonAssets = await buildStep
          .findAssets(Glob('**/*.registry.json'))
          .where((id) => id.package == rootPackage)
          .toList();

      log.info('📄 Found ${allJsonAssets.length} JSON files');

      // Collect code fragment files
      final allRegistryAssets = await buildStep
          .findAssets(Glob('**/*.registry.dart'))
          .where((id) => id.package == rootPackage)
          .toList();

      log.info('📄 Found ${allRegistryAssets.length} registry files');

      if (allJsonAssets.isEmpty && allRegistryAssets.isEmpty) {
        // Generate empty part file
        final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
        await buildStep.writeAsString(outputId, _generateEmptyPartFile(mainFileName));
        log.info('✅ Generated empty part file');
        return;
      }

      // Load and sort classes using JSON metadata
      final allClasses = <Map<String, dynamic>>[];
      for (final assetId in allJsonAssets) {
        try {
          final content = await buildStep.readAsString(assetId);
          final Map<String, dynamic> data = json.decode(content);
          final classes = (data['classes'] as List<dynamic>).cast<Map<String, dynamic>>();
          allClasses.addAll(classes);
        } catch (e) {
          log.warning('Could not process JSON file ${assetId.path}: $e');
          continue;
        }
      }

      log.info('📊 Total classes found: ${allClasses.length}');

      final sortedClasses = allClasses;//_topologicalSort(allClasses);

      // Load imports from registry files
      final imports = <String>{};
      for (final assetId in allRegistryAssets) {
        try {
          final content = await buildStep.readAsString(assetId);
          final lines = content.split('\n');
          for (final line in lines) {
            if (line.trim().startsWith('import ')) {
              imports.add(line.trim());
            }
          }
        } catch (e) {
          log.warning('Could not process registry file ${assetId.path}: $e');
        }
      }

      final generatedCode = _generatePartFileCode(mainFileName, sortedClasses, imports);
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, generatedCode);
      log.info('✅ Successfully generated part file with ${sortedClasses.length} classes');

    } catch (e, stackTrace) {
      log.severe('❌ Error in CombinedRegistryAggregator: $e');
      log.fine('Stack trace: $stackTrace');

      // Generate empty part file as fallback
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, _generateEmptyPartFile(mainFileName));
    }
  }

  String _generateEmptyPartFile(String mainFileName) {
    return '''// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated by velix registry builder

part of '$mainFileName';

void registerAll() {
  // No @Dataclass annotated classes found
}
''';
  }

  String _generatePartFileCode(
      String mainFileName,
      List<Map<String, dynamic>> sortedClasses,
      Set<String> imports,
      ) {
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by velix registry builder');
    buffer.writeln();
    buffer.writeln("part of '$mainFileName';");
    buffer.writeln();

    // Add imports (these will be available to the main file)
    for (final import in imports.toList()..sort()) {
      buffer.writeln(import);
    }
    buffer.writeln();

    buffer.writeln('void registerAll() {');

    if (sortedClasses.isEmpty) {
      buffer.writeln('  // No @Dataclass annotated classes found');
      buffer.writeln('}');
      return buffer.toString();
    }

    // Generate variables in dependency order
    final typeToVariable = <String, String>{};
    for (final classData in sortedClasses) {
      final typeName = classData['type'] as String;
      final variableName = classData['variableName'] as String;
      typeToVariable[typeName] = variableName;
    }

    // Generate code for each class in sorted order
    for (final classData in sortedClasses) {
      final typeName = classData['type'] as String;
      final superClass = classData['superClass'] as String;
      final deps = (classData['dependencies'] as List<dynamic>).cast<String>();
      final variableName = classData['variableName'] as String;

      buffer.writeln('  // $typeName');
      buffer.write('  final $variableName = type<$typeName>(');

      final params = <String>[];

      if (superClass != 'Object' && typeToVariable.containsKey(superClass)) {
        params.add('superClass: ${typeToVariable[superClass]}');
      }

      if (deps.isNotEmpty) {
        final depVars = deps
            .where((d) => typeToVariable.containsKey(d))
            .map((d) => typeToVariable[d]!)
            .toList();
        if (depVars.isNotEmpty) {
          params.add('dependencies: [${depVars.join(', ')}]');
        }
      }

      buffer.write(params.join(', '));
      buffer.writeln(');');
    }

    buffer.writeln();
    buffer.writeln('  // Available variables: ${typeToVariable.values.join(', ')}');
    buffer.writeln('}');

    return buffer.toString();
  }

// ... keep your existing _topologicalSort method
}

/// ----------------------------
/// Builder factories
/// ----------------------------
Builder registryPerFileBuilder(BuilderOptions options) => RegistryPerFileBuilder();
Builder combinedRegistryAggregator(BuilderOptions options) => CombinedRegistryAggregator();