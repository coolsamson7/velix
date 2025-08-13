import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

class CommandGenerator extends Generator {
  // internal

  String getExtends(ClassElement classElement) {
    // Get the superclass element

    final superClassElement = classElement.supertype;

    if (superClassElement == null) {
      print('No superclass for ${classElement.name}');
      return "";
    }

    // Get the type arguments applied to the superclass
    final typeArguments = superClassElement.typeArguments;

    if (typeArguments.isEmpty) {
      print('Superclass has no generic arguments for ${classElement.name}');
      return "";
    }

    final firstArg = typeArguments.first;
    //print('First generic argument: ${firstArg.getDisplayString(withNullability: false)}');

    return firstArg.getDisplayString();
  }

  // override

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    final output = StringBuffer();

    for (final clazz in library.classes) {
      final commands = <MethodElement>[];

      for (final method in clazz.methods) {
        if (_isCommandMethod(method)) {
          commands.add(method);
        }
      }

      if (commands.isEmpty) continue;

      final fileName = buildStep.inputId.uri.pathSegments.last;

      // Add the part-of directive

      output.writeln("part of '$fileName';\n");

      final className = clazz.name;
      final mixinName = '${className}Commands';

      final type = getExtends(clazz);
      output.writeln('mixin $mixinName on CommandController<$type> {');

      // Generate initCommands

      output.writeln('  // override');
      output.writeln();

      output.writeln('  @override');
      output.writeln('  void initCommands() {');
      for (final method in commands) {
        final publicName = method.name.replaceFirst('_', '');
        final name = _getCommandAnnotation(method)!.peek('name')?.stringValue ?? publicName;
        final label = _getCommandAnnotation(method)!.peek('label')?.stringValue ?? '';

        output.write('    addCommand("$name", _$publicName');

        if ( label.isNotEmpty) {
          output.write(', label: \'$label\'');
        }

        output.writeln(');');
      }
      output.writeln('  }');

      //  _<command>()...

      output.writeln();
      output.writeln('  // command declarations');
      output.writeln();

      for (final method in commands) {
        final publicName = method.name.replaceFirst('_', '');
        final signature = method.parameters.map((param) {
          final typeStr = param.type.getDisplayString();
          return '$typeStr ${param.name}';
        }).join(', ');

        output.writeln('  void _$publicName($signature);');
      } // for

      // <command>(...)

      output.writeln();
      output.writeln('  // command bodies');
      output.writeln();

      for (final method in commands) {
        final publicName = method.name.replaceFirst('_', '');
        final signature = method.parameters.map((param) {
          final typeStr = param.type.getDisplayString();
          return '$typeStr ${param.name}';
        }).join(', ');
        final argList = method.parameters.map((param) => param.name).join(', ');

        output.writeln('  void $publicName($signature) {');
        output.writeln('    execute("$publicName", [$argList]);');
        output.writeln('  }');
      } // for

      output.writeln('}');
      output.writeln();
    } // for

    return output.toString();
  }

  bool _isCommandMethod(MethodElement method) {
    return method.metadata.any((m) =>
    m.computeConstantValue()?.type?.getDisplayString() == 'Command');
  }

  ConstantReader? _getCommandAnnotation(MethodElement method) {
    for (final meta in method.metadata) {
      final constantValue = meta.computeConstantValue();
      if (constantValue == null) continue;
      if (constantValue.type?.getDisplayString() == 'Command') {
        return ConstantReader(constantValue);
      }
    }

    return null;
  }
}

// function for build.yaml

Builder commandBuilder(BuilderOptions options) => LibraryBuilder(CommandGenerator(), generatedExtension: '.command.g.dart');