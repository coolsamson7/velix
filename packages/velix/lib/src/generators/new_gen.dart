import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';


/// ----------------------------
/// Per-file builder
/// ----------------------------
class RegistryPerFileBuilder extends Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.registry.dart', '.registry.json']
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final library = await buildStep.resolver.libraryFor(buildStep.inputId);

    final injectableClasses = <ClassElement>[];

    // analyzer >= 5.x (8.0): use topLevelDeclarations instead of topLevelElements
    for (var declaration in library.classes) {
      if (declaration is ClassElement) {
        for (final annotation in declaration.metadata.annotations) {
          final obj = annotation.computeConstantValue();
          if (obj?.type?.getDisplayString(withNullability: false) == 'Injectable') {
            injectableClasses.add(declaration);
          }
        }
      }
    }

    if (injectableClasses.isEmpty) return;

    final buffer = StringBuffer();
    final meta = <Map<String, dynamic>>[];

    for (var cls in injectableClasses) {
      final typeName = cls.name;
      final superClass = cls.supertype?.getDisplayString(withNullability: false) ?? 'Object';

      final dependencies = [];/*cls.constructors
          .expand((c) => c.parameters)
          .map((p) => p.type.getDisplayString(withNullability: false))
          .toList();*/

      // JSON metadata
      meta.add({
        'type': typeName,
        'superClass': superClass,
        'dependencies': dependencies,
      });

      // Dart registry snippet
      buffer.writeln('final ${typeName}Registry = register<$typeName>(');
      if (superClass != 'Object') {
        buffer.writeln('  superClass: ${superClass.camelCase}Registry,');
      }
      if (dependencies.isNotEmpty) {
        buffer.writeln('  dependencies: [${dependencies.map((d) => 'type<$d>()').join(', ')}],');
      }
      buffer.writeln(');');
    }

    // Write Dart snippet
    final dartOutputId = buildStep.inputId.changeExtension('.registry.dart');
    await buildStep.writeAsString(dartOutputId, buffer.toString());

    // Write JSON metadata
    final jsonOutputId = buildStep.inputId.changeExtension('.registry.json');
    await buildStep.writeAsString(
      jsonOutputId,
      const JsonEncoder.withIndent('  ').convert(meta),
    );
  }
}

/// ----------------------------
/// Aggregator builder
/// ----------------------------
class CombinedRegistryAggregator implements Builder {
  @override
  final buildExtensions = const {
    r'$package$': ['combined_registry.dart']
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final allJsonAssets = await buildStep.findAssets(Glob('**/*.registry.json')).toList();
    if (allJsonAssets.isEmpty) return;

    // Collect all metadata from cached JSON files
    final allMeta = <Map<String, dynamic>>[];
    for (var assetId in allJsonAssets) {
      final content = await buildStep.readAsString(assetId);
      final List<dynamic> jsonList = json.decode(content);
      allMeta.addAll(jsonList.cast<Map<String, dynamic>>());
    }

    // Sort by dependency hierarchy (superClass first)
    final sortedMeta = _topologicalSort(allMeta);

    // Generate combined registry code
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED COMBINED REGISTRY - DO NOT EDIT');
    buffer.writeln('import \'package:injectable/injectable.dart\';');
    buffer.writeln('void registerAll() {');

    for (var meta in sortedMeta) {
      final typeName = meta['type'];
      final superClass = meta['superClass'];
      final deps = (meta['dependencies'] as List<dynamic>).cast<String>();

      buffer.write('  final ${typeName.camelCase} = register<$typeName>(');

      if (superClass != 'Object') {
        buffer.write('superClass: ${superClass.camelCase}, ');
      }

      if (deps.isNotEmpty) {
        buffer.write('dependencies: [${deps.map((d) => 'type<$d>()').join(', ')}]');
      }

      buffer.writeln(');');
    }

    buffer.writeln('}');

    final outputId = AssetId(buildStep.inputId.package, 'lib/combined_registry.dart');
    final newContent = buffer.toString();

    // Skip writing if unchanged to preserve caching
    if (await buildStep.canRead(outputId)) {
      final oldContent = await buildStep.readAsString(outputId);
      if (oldContent == newContent) return;
    }

    await buildStep.writeAsString(outputId, newContent);
  }

  /// Simple topological sort based on superClass
  List<Map<String, dynamic>> _topologicalSort(List<Map<String, dynamic>> meta) {
    final graph = <String, List<String>>{};
    final nodes = <String, Map<String, dynamic>>{};

    for (var m in meta) {
      final type = m['type'] as String;
      nodes[type] = m;
      final parent = m['superClass'] as String;
      if (parent != 'Object') {
        graph.putIfAbsent(parent, () => []).add(type);
      } else {
        graph.putIfAbsent(type, () => []);
      }
    }

    final visited = <String>{};
    final result = <Map<String, dynamic>>[];

    void visit(String node) {
      if (visited.contains(node)) return;
      visited.add(node);
      for (var child in graph[node] ?? []) {
        visit(child);
      }
      if (nodes.containsKey(node)) result.add(nodes[node]!);
    }

    for (var node in nodes.keys) {
      visit(node);
    }

    return result.reversed.toList(); // superclasses first
  }
}

/// ----------------------------
/// camelCase helper
/// ----------------------------
extension _CamelCase on String {
  String get camelCase => isEmpty ? '' : this[0].toLowerCase() + substring(1);
}
