import 'dart:async';

import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

Builder widgetBuilder(BuilderOptions options) => WidgetBuilder();

Uri? getSourceUri(ClassElement2 element) {
  // Every class belongs to a library
  final lib = element.library2;

  return lib.uri;

  // The `LibraryElement2` gives you access to the defining compilation unit
  //final definingUnit = lib.definingCompilationUnit;

  // That has the URI of the file
  //return definingUnit.source2?.uri;
}



bool hasAnnotationByName(ClassElement2 element, String annotationName) {
  return element.metadata2.annotations.any((annotation) {
    final name = annotation.element?.enclosingElement3?.name;
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
    final classes = <ClassElement2>[];

    // Find all Dart files in lib/
    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      final library = await resolver.libraryFor(input, allowSyntaxErrors: true);
      for (final element in library.classes) {
          if (hasAnnotationByName(element, "WidgetAdapter"))
            classes.add(element);
        }
    }

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln("import 'package:velix/velix.dart';");

    final seenImports = <String>{};
    for (final clazz in classes) {
      final sourceUri = getSourceUri(clazz).toString();
      if (seenImports.add(sourceUri)) {
        buffer.writeln("import '$sourceUri';");
      }
    }

    buffer.writeln();

    buffer.writeln('void registerWidgets() {');
    for (final clazz in classes) {
      buffer.writeln("   ValuedWidget.register(${clazz.name3}());"); // ?
    }

    buffer.writeln('}');

    // Write to widget_registry.g.dart

    final fileName = p.basenameWithoutExtension(buildStep.inputId.path);

    final isTestFile = buildStep.inputId.toString().contains('|test/');
    var dir = isTestFile ? "test" : "lib";

    final assetId = AssetId(buildStep.inputId.package, '$dir/$fileName.widget_registry.g.dart');
    await buildStep.writeAsString(assetId, buffer.toString());
  }
}