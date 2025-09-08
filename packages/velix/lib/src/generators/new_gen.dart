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
        if (!isDataclass) continue;

        // Find AST node for line/col
        final node = unit.declarations
            .whereType<ClassDeclaration>()
            .firstWhere((d) => d.name.lexeme == cls.name, orElse: () => throw Exception('Class node not found'));

        final loc = lineInfo.getLocation(node.offset);
        final startLine = loc.lineNumber;
        final startCol = loc.columnNumber;

        final typeName = cls.name;
        final superClass = cls.supertype?.getDisplayString(withNullability: false) ?? 'Object';
        final dependencies = <String>[]; // currently empty

        // JSON metadata includes exact offsets
        final meta = {
          'type': typeName,
          'superClass': superClass,
          'dependencies': dependencies,
          'sourceFile': path,
          'variableName': '${typeName}Type',
          'line': startLine,
          'column': startCol,
          'fragmentStartOffset': node.offset,
          'fragmentEndOffset': node.end,
        };
        classesWithDataclass.add(meta);

        imports.add(_getImportPath(path));

        // Code fragment with location markers
        final fragment = _generateClassRegistrationCode(
          typeName!,
          superClass,
          dependencies,
          startLine,
          startCol,
          node.offset,
          node.end,
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

      // Write code fragment file
      if (codeFragments.isNotEmpty) {
        final codeOut = buildStep.inputId.changeExtension('.registry.dart');
        final buffer = StringBuffer()
          ..writeln('// REGISTRY FRAGMENT - DO NOT EDIT')
          ..writeln('// Source: $path')
          ..writeln();

        for (final import in imports) {
          buffer.writeln("import '$import';");
        }
        buffer.writeln();

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

  String _getImportPath(String sourceFile) =>
      sourceFile.startsWith('lib/') ? sourceFile.substring(4) : sourceFile;

  String _generateClassRegistrationCode(
      String typeName,
      String superClass,
      List<String> dependencies,
      int startLine,
      int startCol,
      int startOffset,
      int endOffset,
      ) {
    final variableName = '${typeName.toLowerCase()}Type';
    final buffer = StringBuffer();

    buffer.writeln('// FRAGMENT_START:$typeName [$startOffset-$endOffset]');
    buffer.writeln('// Registration for $typeName ($startLine:$startCol)');
    buffer.write('final $variableName = type<$typeName>(');

    final params = <String>[];
    if (superClass != 'Object') params.add('/* RESOLVE_SUPER:$superClass */');
    if (dependencies.isNotEmpty) params.add('/* RESOLVE_DEPS:${dependencies.join(',')} */');

    buffer.write(params.join(', '));
    buffer.writeln(');');
    buffer.writeln('// FRAGMENT_END:$typeName [$startOffset-$endOffset]');

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

      // Load metadata for sorting
      final allClasses = <Map<String, dynamic>>[];
      final fragmentsByClass = <String, String>{};
      final imports = <String>{};

      for (final assetId in allJsonAssets) {
        try {
          final content = await buildStep.readAsString(assetId);
          final Map<String, dynamic> data = json.decode(content);
          allClasses.addAll((data['classes'] as List).cast<Map<String, dynamic>>());
        } catch (e) {
          log.warning('Could not read JSON ${assetId.path}: $e');
        }
      }

      for (final assetId in allRegistryAssets) {
        try {
          final content = await buildStep.readAsString(assetId);
          // Extract imports
          for (final line in content.split('\n')) {
            if (line.trim().startsWith('import ')) imports.add(line.trim());
          }
          // Use entire fragment text as-is from start/end offsets
          fragmentsByClass.addAll(_extractFragmentsFromContent(content));
        } catch (e) {
          log.warning('Could not read registry fragment ${assetId.path}: $e');
        }
      }

      // Sort classes by file, line, column
      allClasses.sort((a, b) {
        final fileA = a['sourceFile'] as String;
        final fileB = b['sourceFile'] as String;
        final cmpFile = fileA.compareTo(fileB);
        if (cmpFile != 0) return cmpFile;

        final cmpLine = (a['line'] as int).compareTo(b['line'] as int);
        if (cmpLine != 0) return cmpLine;

        return (a['column'] as int).compareTo(b['column'] as int);
      });

      final generatedCode = _generatePartFileCode(mainFileName, imports, allClasses, fragmentsByClass);
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, generatedCode);
      log.info('✅ Successfully generated part file');

    } catch (e, stackTrace) {
      log.severe('❌ Error in CombinedRegistryAggregator: $e');
      log.fine('$stackTrace');
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, _generateEmptyPartFile(mainFileName));
    }
  }

  Map<String, String> _extractFragmentsFromContent(String content) {
    final fragments = <String, String>{};
    final lines = content.split('\n');
    String? currentClass;
    final fragmentLines = <String>[];
    bool inFragment = false;

    for (final line in lines) {
      if (line.startsWith('// FRAGMENT_START:')) {
        currentClass = line.substring('// FRAGMENT_START:'.length).split(' ').first;
        fragmentLines.clear();
        inFragment = true;
      } else if (line.startsWith('// FRAGMENT_END:')) {
        if (currentClass != null && fragmentLines.isNotEmpty) {
          fragments[currentClass] = fragmentLines.join('\n');
        }
        currentClass = null;
        inFragment = false;
      } else if (inFragment) {
        fragmentLines.add(line);
      }
    }
    return fragments;
  }

  String _generatePartFileCode(
      String mainFileName,
      Set<String> imports,
      List<Map<String, dynamic>> sortedClasses,
      Map<String, String> fragmentsByClass,
      ) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// Generated by velix registry builder')
      ..writeln()
      ..writeln("part of '$mainFileName';")
      ..writeln();

    for (final import in imports.toList()..sort()) buffer.writeln(import);
    buffer.writeln();

    buffer.writeln('void registerAll() {');

    if (sortedClasses.isEmpty) {
      buffer.writeln('  // No @Dataclass annotated classes found');
    } else {
      final typeToVariable = <String, String>{};
      for (final classData in sortedClasses) {
        final typeName = classData['type'] as String;
        final variableName = classData['variableName'] as String;
        typeToVariable[typeName] = variableName;

        final fragment = fragmentsByClass[typeName] ?? _generateFallbackFragment(classData);

        // Indent
        final indented = fragment.split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => '  $line')
            .join('\n');

        buffer.writeln(indented);
        buffer.writeln();
      }

      final variables = typeToVariable.values.toList()..sort();
      buffer.writeln('  // Available variables: ${variables.join(', ')}');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _generateFallbackFragment(Map<String, dynamic> classData) {
    final typeName = classData['type'] as String;
    final variableName = classData['variableName'] as String;
    final line = classData['line'] as int;
    final col = classData['column'] as int;

    return '''// Registration for $typeName ($line:$col)
final $variableName = type<$typeName>(/* fallback */);''';
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
Builder registryPerFileBuilder(BuilderOptions options) => RegistryPerFileBuilder();
Builder combinedRegistryAggregator(BuilderOptions options) => CombinedRegistryAggregator();
