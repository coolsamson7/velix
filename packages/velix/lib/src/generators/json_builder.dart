import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

Builder registryJSONBuilder(BuilderOptions options) =>  JsonDescriptorBuilder();


class JsonDescriptorBuilder extends Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.new_registry.json']
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final path = buildStep.inputId.path;

    if (!path.endsWith('.dart') ||
        path.contains('.g.dart') ||
        path.contains('.part.dart') ||
        path.contains('.freezed.dart') ||
        path.contains('.gr.dart')) return;

    try {
      final lib = await buildStep.resolver.libraryFor(buildStep.inputId);
      final session = lib.session;
      final parsedLib = session.getParsedLibraryByElement(lib) as ParsedLibraryResult;
      final unit = parsedLib.units.first.unit;

      final List<Map<String, dynamic>> classes = [];

      // Filter relevant classes
      bool isRelevant(InterfaceElement e) =>
          e.metadata.annotations.any((a) =>
              ['Dataclass', 'Injectable', 'Module', 'Scope']
                  .contains(a.element?.enclosingElement?.name));

      final elements = [...lib.classes, ...lib.enums].where(isRelevant);

      for (final e in elements) {
        if (e is ClassElement) {
          final location = unit.lineInfo.getLocation(
              unit.declarations.firstWhere(
                      (d) => d is ClassDeclaration && d.name.lexeme == e.name)
                  .offset);

          classes.add(_classToJson(e, location));
        } else if (e is EnumElement) {
          classes.add(_enumToJson(e));
        }
      }

      if (classes.isNotEmpty) {
        final jsonOut = buildStep.inputId.changeExtension('.new_registry.json');
        await buildStep.writeAsString(
          jsonOut,
          const JsonEncoder.withIndent('  ').convert({'classes': classes}),
        );
      }
    } catch (e, st) {
      log.warning('Failed to generate JSON for $path: $e\n$st');
    }
  }

  Map<String, dynamic> _classToJson(ClassElement element, CharacterLocation location) {
    return {
      'name': element.name,
      'superClass': element.supertype?.isDartCoreObject == false
          ? element.supertype!.element.name
          : null,
      'properties': element.fields
          .where((field) => !field.isStatic && !field.isPrivate)
          .map((f) => {
            'name': f.name,
            'type': f.type.getDisplayString(withNullability: true),
            'isNullable': f.type.nullabilitySuffix == NullabilitySuffix.question,
            'isFinal': f.isFinal,
            'annotations': [
              for (final a in f.metadata.annotations){
              'name': a.element?.enclosingElement?.name,
              'value': a.computeConstantValue()?.type?.getDisplayString()
              }
            ]
            })
      .toList(),
      'methods': element.methods
          .where((m) => !m.isPrivate)
          .map((m) =>  {
            'name': m.name,
            'parameters': [
              for (final p in m.formalParameters)
                {
                  'name': p.name,
                  'type': p.type.getDisplayString(withNullability: true),
                  'isNamed': p.isNamed,
                  'isRequired': p.isRequiredNamed || p.isRequiredPositional,
                  'isNullable': p.isOptional || p.isOptionalNamed,
                }
            ],
            'returnType': m.returnType.getDisplayString(withNullability: true),
            'isAsync': m.returnType.isDartAsyncFuture,
            'annotations': [
              for (final a in m.metadata.annotations)
                {
                  'name': a.element?.enclosingElement?.name,
                  'value': a.computeConstantValue()?.type?.getDisplayString()
                }
            ],
          })
          .toList(),
      'annotations': [
        for (final a in element.metadata.annotations)
          {
            'name': a.element?.enclosingElement?.name,
            'value': a.computeConstantValue()?.type?.getDisplayString()
          }
      ],
      'isAbstract': element.isAbstract,
      'location': '${location.lineNumber}:${location.columnNumber}',
    };
  }

  Map<String, dynamic> _enumToJson(EnumElement element) {
    return {
      'name': element.name,
      'values': element.fields.where((f) => f.isEnumConstant).map((f) => f.name).toList(),
      'annotations': [
        for (final a in element.metadata.annotations)
          {
            'name': a.element?.enclosingElement?.name,
            'value': a.computeConstantValue()?.type?.getDisplayString()
          }
      ],
    };
  }
}

class JsonDescriptorAggregator extends Builder {
  // instance data

  String prefix;

  // constructor

  JsonDescriptorAggregator({required this.prefix});

  // override

  @override
  final buildExtensions = const {'.dart': ['.types.g.json']};

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final rootPackage = buildStep.inputId.package;

    final mergedStream = StreamGroup.merge([
      buildStep.findAssets(Glob('$prefix/*.new_registry.json')),
      buildStep.findAssets(Glob('$prefix/**/*.new_registry.json'))
    ]);

    final allJsonAssets = await mergedStream.where((id) => id.package == rootPackage).toList();

    List<Map<String, dynamic>> classes = [];
    Map<String, dynamic> result = {
      "classes": classes
    };

    for (final assetId in allJsonAssets) {
      final jsonString = await buildStep.readAsString(assetId);

      // Parse JSON

      final dynamic jsonData = jsonDecode(jsonString);

      for (var clazz in jsonData["classes"])
        classes.add(clazz);
    } // for

    // Generate Dart code

    final buffer = StringBuffer();


    var encoder = const JsonEncoder.withIndent('  ');

    // Convert the map to a pretty-printed JSON string
    var str = encoder.convert(result);

    buffer.writeln(str);

    final outputId = buildStep.inputId.changeExtension('.types.g.json');
    await buildStep.writeAsString(outputId, buffer.toString());

    log.info('✅ JSON registry combined successfully into ${outputId.path}');
  }
}


/// ----------------------------
/// Builder factory
/// ----------------------------
///
Builder jsonRegistryAggregator(BuilderOptions options) {
  final config = options.config;
  final functionName = config['function_name'] as String? ?? 'registerTypes';
  final partOf = config['part_of'] as String? ?? '';
  final prefix = config['prefix'] as String? ?? 'lib';
  return JsonDescriptorAggregator(prefix: prefix);
}
