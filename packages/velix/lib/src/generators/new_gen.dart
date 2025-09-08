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

      // Get parsed AST so we can resolve line/col
      final session = lib.session;
      final parsedLib = await session.getParsedLibraryByElement(lib) as ParsedLibraryResult;
      final unit = parsedLib.units.first.unit;
      final lineInfo = parsedLib.units.first.lineInfo;

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

        // find AST node for this class
        final node = unit.declarations
            .whereType<ClassDeclaration>()
            .firstWhere((d) => d.name.lexeme == cls.name, orElse: () => throw Exception("jj"));

        int line = -1;
        int col = -1;
        if (node != null) {
          final loc = lineInfo.getLocation(node.offset);
          line = loc.lineNumber;
          col = loc.columnNumber;
        }

        final typeName = cls.name;
        final superClass = cls.supertype?.getDisplayString(withNullability: false) ?? 'Object';

        final dependencies = <String>[]; // left empty for now

        final meta = {
          'type': typeName,
          'superClass': superClass,
          'dependencies': dependencies,
          'sourceFile': buildStep.inputId.path,
          'variableName': '${typeName}Type',
          'line': line,
          'column': col,
        };
        classesWithDataclass.add(meta);

        imports.add(_getImportPath(buildStep.inputId.path));

        final codeFragment = _generateClassRegistrationCode(
          typeName!,
          superClass,
          dependencies,
          cls,
        );

        codeFragments.add(codeFragment);
      }

      if (classesWithDataclass.isNotEmpty) {
        final jsonOut = buildStep.inputId.changeExtension('.registry.json');
        await buildStep.writeAsString(
          jsonOut,
          const JsonEncoder.withIndent('  ').convert({'classes': classesWithDataclass}),
        );
      }

      if (codeFragments.isNotEmpty) {
        final codeOut = buildStep.inputId.changeExtension('.registry.dart');
        final buffer = StringBuffer()
          ..writeln('// REGISTRY FRAGMENT - DO NOT EDIT')
          ..writeln('// Source: ${buildStep.inputId.path}')
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
      log.warning('Skipping ${buildStep.inputId.path}: $e');
      log.fine('$stackTrace');
    }
  }

  String _getImportPath(String sourceFile) =>
      sourceFile.startsWith('lib/') ? sourceFile.substring(4) : sourceFile;

  String _generateClassRegistrationCode(
      String typeName,
      String superClass,
      List<String> dependencies,
      ClassElement cls,
      ) {
    final variableName = '${typeName.toLowerCase()}Type';
    final buffer = StringBuffer();

    buffer.writeln('// Registration for $typeName');
    buffer.write('final $variableName = type<$typeName>(');

    final params = <String>[];
    if (superClass != 'Object') params.add('/* superClass will be resolved */');
    if (dependencies.isNotEmpty) params.add('/* dependencies will be resolved */');

    buffer.write(params.join(', '));
    buffer.write(');');
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

      final fragments = <String>[];
      final imports = <String>{};
      for (final assetId in allRegistryAssets) {
        try {
          final content = await buildStep.readAsString(assetId);
          fragments.add(content);
          for (final line in content.split('\n')) {
            if (line.trim().startsWith('import ')) imports.add(line.trim());
          }
        } catch (e) {
          log.warning('Could not read registry fragment ${assetId.path}: $e');
        }
      }

      final generatedCode =
      _generatePartFileCode(mainFileName, imports, fragments, allClasses);
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, generatedCode);
    } catch (e, stackTrace) {
      log.severe('❌ Error in CombinedRegistryAggregator: $e');
      log.fine('$stackTrace');
      final outputId = buildStep.inputId.changeExtension('.registry.g.dart');
      await buildStep.writeAsString(outputId, _generateEmptyPartFile(mainFileName));
    }
  }

  String _generatePartFileCode(
      String mainFileName,
      Set<String> imports,
      List<String> fragments,
      List<Map<String, dynamic>> allClasses,
      ) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// Generated by velix registry builder')
      ..writeln()
      ..writeln("part of '$mainFileName';")
      ..writeln();

    for (final i in imports.toList()..sort()) {
      buffer.writeln(i);
    }
    buffer.writeln();

    buffer.writeln('void registerAll() {');
    if (fragments.isEmpty) {
      buffer.writeln('  // No @Dataclass annotated classes found');
    } else {
      for (final frag in fragments) {
        buffer.writeln(frag);
      }
    }
    buffer.writeln('}');
    return buffer.toString();
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
