import 'dart:async';
import 'dart:convert';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// ----------------------------
/// Per-class builder
/// ----------------------------
class RegistryPerFileBuilder extends Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.registry.json', '.registry.dart']
  };

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

      final classesWithDataclass = <Map<String, dynamic>>[];
      final codeFragments = <String>[];
      final imports = <String>{};

      for (final cls in lib.classes) {
        // Check for @Dataclass annotation
        final isDataclass = cls.metadata.annotations.any((annotation) {
          final obj = annotation.computeConstantValue();
          return obj?.type?.getDisplayString(withNullability: false) == 'Dataclass';
        });

        if (!isDataclass)
          continue;

        // Find AST node for line/col
        final node = unit.declarations
            .whereType<ClassDeclaration>()
            .firstWhere(
              (d) => d.name.lexeme == cls.name,
          orElse: () => throw Exception('Class node not found'),
        );

        final startLoc = lineInfo.getLocation(node.offset);
        final endLoc = lineInfo.getLocation(node.end);

        final typeName = cls.name;
        final superClass = cls.supertype?.getDisplayString(withNullability: false) ?? 'Object';
        final dependencies = <String>[]; // currently empty

        // Add all file imports
        for (final directive in unit.directives.whereType<ImportDirective>()) {
          final importPath = directive.uri.stringValue;
          if (importPath != null)
            imports.add(importPath);
        }

        // JSON metadata
        final meta = {
          'type': typeName,
          'superClass': superClass,
          'dependencies': dependencies,
          'sourceFile': path,
          'variableName': '${typeName}Type',
          'startLine': startLoc.lineNumber,
          'startColumn': startLoc.columnNumber,
          'endLine': endLoc.lineNumber,
          'endColumn': endLoc.columnNumber,
          'imports': imports.toList(),
        };
        classesWithDataclass.add(meta);

        // Generate code fragment: type<...>().location(...)
        final fragment = _generateClassRegistrationCode(
          typeName!,
          superClass,
          dependencies,
          path,
          startLoc.lineNumber,
          startLoc.columnNumber,
        );
        codeFragments.add(fragment);
      }

      // Write JSON metadata
      if (classesWithDataclass.isNotEmpty) {
        final jsonOut = buildStep.inputId.changeExtension('.registry.json');
        await buildStep.writeAsString(
          jsonOut,
          const JsonEncoder.withIndent('  ').convert({'classes': classesWithDataclass}),
        );
      }

      // Write code fragment
      if (codeFragments.isNotEmpty) {
        final codeOut = buildStep.inputId.changeExtension('.registry.dart');
        final buffer = StringBuffer()
          ..writeln('// REGISTRY FRAGMENT - DO NOT EDIT')
          ..writeln('// Source: $path')
          ..writeln();

        for (final fragment in codeFragments) {
          buffer.writeln(fragment);
          buffer.writeln();
        }

        await buildStep.writeAsString(codeOut, buffer.toString());
      }
    } catch (e, stackTrace) {
      log.warning('Skipping $path: $e');
      log.fine('$stackTrace');
    }
  }

  String _generateClassRegistrationCode(
      String typeName,
      String superClass,
      List<String> dependencies,
      String sourceFile,
      int startLine,
      int startColumn,
      ) {
    final variableName = '${typeName.toLowerCase()}Type';
    final buffer = StringBuffer();

    buffer.write('final $variableName = type<$typeName>(');

    final params = <String>[];
    if (superClass != 'Object') params.add('/* RESOLVE_SUPER:$superClass */');
    if (dependencies.isNotEmpty) params.add('/* RESOLVE_DEPS:${dependencies.join(',')} */');

    buffer.write(params.join(', '));
    buffer.writeln(').location("$sourceFile:$startLine:$startColumn");');

    return buffer.toString();
  }
}

/// ----------------------------
/// Aggregator builder
/// ----------------------------
class CombinedRegistryAggregator extends Builder {
  @override
  final buildExtensions = const {'.dart': ['.registry.g.dart']};

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

      final allRegistryAssets = await buildStep
          .findAssets(Glob('**/*.registry.dart'))
          .where((id) => id.package == rootPackage)
          .toList();

      // Load metadata for sorting and dependency resolution
      final allClasses = <Map<String, dynamic>>[];
      for (final assetId in allJsonAssets) {
        try {
          final content = await buildStep.readAsString(assetId);
          final Map<String, dynamic> data = json.decode(content);
          allClasses.addAll((data['classes'] as List).cast<Map<String, dynamic>>());
        } catch (e) {
          log.warning('Could not read JSON ${assetId.path}: $e');
        }
      }

      // Sort classes by location (file, then startLine, then startColumn)
      allClasses.sort((a, b) {
        final fileComparison = (a['sourceFile'] as String).compareTo(b['sourceFile'] as String);
        if (fileComparison != 0) return fileComparison;

        final lineComparison = (a['startLine'] as int).compareTo(b['startLine'] as int);
        if (lineComparison != 0) return lineComparison;

        return (a['startColumn'] as int).compareTo(b['startColumn'] as int);
      });

      // Combine all code fragments
      final buffer = StringBuffer()
        ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
        ..writeln('// Generated by velix registry builder')
        ..writeln()
        ..writeln("part of '$mainFileName';")
        ..writeln();

      // Gather imports from metadata
      final importSet = <String>{};
      for (final cls in allClasses) {
        importSet.addAll((cls['imports'] as List<dynamic>).cast<String>());
      }

      for (final importPath in importSet.toList()..sort()) {
        buffer.writeln("import '$importPath';");
      }
      buffer.writeln();

      buffer.writeln('void registerAll() {');
      if (allClasses.isEmpty) {
        buffer.writeln('  // No @Dataclass annotated classes found');
      } else {
        for (final cls in allClasses) {
          final variableName = cls['variableName'] as String;
          final typeName = cls['type'] as String;
          final superClass = cls['superClass'] as String;
          final deps = (cls['dependencies'] as List<dynamic>).cast<String>();
          final location = '${cls['sourceFile']}:${cls['startLine']}:${cls['startColumn']}';

          final code = 'final $variableName = type<$typeName>('
              '${superClass != 'Object' ? '/* RESOLVE_SUPER:$superClass */' : ''}'
              '${deps.isNotEmpty ? '/* RESOLVE_DEPS:${deps.join(',')} */' : ''}'
              ').location("$location");';
          buffer.writeln('  $code');
        }
      }
      buffer.writeln('}');
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, buffer.toString());
      log.info('✅ Successfully generated part file');

    } catch (e, stackTrace) {
      log.severe('❌ Error in CombinedRegistryAggregator: $e');
      log.fine('$stackTrace');
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, _generateEmptyPartFile(mainFileName));
    }
  }

  String _generateEmptyPartFile(String mainFileName) => '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated by velix registry builder

part of '$mainFileName';

void registerAll() {
  // No @Dataclass annotated classes found
}
''';
}

/// ----------------------------
/// Builder factories
/// ----------------------------
Builder registryPerFileBuilder(BuilderOptions options) =>
    RegistryPerFileBuilder();
Builder combinedRegistryAggregator(BuilderOptions options) =>
    CombinedRegistryAggregator();
