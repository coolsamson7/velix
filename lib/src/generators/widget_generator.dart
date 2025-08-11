import 'dart:async';
import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

Builder widgetBuilder(BuilderOptions options) => WidgetBuilder();

bool hasAnnotationByName(Element element, String annotationName) {
  return element.metadata.any((annotation) {
    final name = annotation.element?.enclosingElement?.name;
    // For a simple annotation like @Foo, name is 'Foo'.
    // If unresolved it can be null, so check safe.
    return name == annotationName;
  });
}

class WidgetBuilder implements Builder {
  // Outputs a fixed file in /lib; adjust as needed.
  @override
  final buildExtensions = const {
    //r'$lib$': ['.widget_registry.g.dart']
    '.dart': ['.widget_registry.g.dart']
  };

  // internal

  // override

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    final classes = <ClassElement>[];

    // Find all Dart files in lib/
    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      final library = await resolver.libraryFor(input, allowSyntaxErrors: true);
      for (final element in library.topLevelElements) {
        if (element is ClassElement) {
          if (hasAnnotationByName(element, "WidgetAdapter"))
            classes.add(element);
        }
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln("import 'package:velix/velix.dart';");

    final seenImports = <String>{};
    for (final clazz in classes) {
      final sourceUri = clazz.source.uri.toString();
      if (seenImports.add(sourceUri)) {
        buffer.writeln("import '$sourceUri';");
      }
    }

    buffer.writeln();

    buffer.writeln('void registerWidgets() {');
    for (final clazz in classes) {
      buffer.writeln("   ValuedWidget.register(${clazz.name}());");
    }

    buffer.writeln('}');

    // Write to widget_registry.g.dart

    final fileName = p.basenameWithoutExtension(buildStep.inputId.path);

    final assetId = AssetId(buildStep.inputId.package, 'lib/${fileName}.widget_registry.g.dart');
    await buildStep.writeAsString(assetId, buffer.toString());
  }
}