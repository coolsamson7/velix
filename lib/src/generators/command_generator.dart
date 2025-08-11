import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';


class CommandGenerator extends Generator {
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

      //output.writeln('import \'package:velix/velix.dart\';')

      final className = clazz.name;
      final mixinName = '_\$${className}Commands';

      output.writeln('mixin $mixinName on CommandController {');

      // Generate initCommands

      output.writeln('  void initCommands() {');
      for (final method in commands) {
        final publicName = method.name.replaceFirst('_', '');
        final paramDeclarations = method.parameters.asMap().entries.map((entry) {
          final i = entry.key;
          final param = entry.value;
          final typeStr = param.type.getDisplayString(withNullability: false);
          return '$typeStr ${param.name} = args[$i] as $typeStr;';
        }).join('\n        ');

        final paramCall = method.parameters.map((p) => p.name).join(', ');

        final name = _getCommandAnnotation(method)!.peek('name')?.stringValue ?? publicName;
        final label = _getCommandAnnotation(method)!.peek('label')?.stringValue ?? '';

        output.write('    addCommand("$name", _$publicName');

        if ( label.isNotEmpty) {
          output.write(', label: \'$label\'');
        }

        output.writeln(');');
        //output.writeln('      execute: (args) {');
        //i//f (method.parameters.isNotEmpty) output.writeln('        $paramDeclarations');
        // output.writeln('        return ${method.name}($paramCall);');
        //output.writeln('      },');
        //output.writeln('    ));');
      }
      output.writeln('  }');

      // Generate public forwarding methods
      for (final method in commands) {
        final publicName = method.name.replaceFirst('_', '');
        final signature = method.parameters.map((param) {
          final typeStr = param.type.getDisplayString(withNullability: false);
          return '$typeStr ${param.name}';
        }).join(', ');
        final argList = method.parameters.map((param) => param.name).join(', ');

        output.writeln('  void $publicName($signature) {');
        output.writeln('    execute("$publicName", [$argList]);');
        output.writeln('  }');

        output.writeln('  void _$publicName($signature);');
      }

      output.writeln('}');
      output.writeln();
    }

    return output.toString();
  }

  bool _isCommandMethod(MethodElement method) {
    return method.metadata.any((m) =>
    m.computeConstantValue()?.type?.getDisplayString(withNullability: false) == 'Command');
  }

  ConstantReader? _getCommandAnnotation(MethodElement method) {
    for (final meta in method.metadata) {
      final constantValue = meta.computeConstantValue();
      if (constantValue == null) continue;
      if (constantValue.type?.getDisplayString(withNullability: false) == 'Command') {
        return ConstantReader(constantValue);
      }
    }
    return null;
  }
}

// function for build.yaml
Builder commandBuilder(BuilderOptions options) =>
    LibraryBuilder(CommandGenerator(), generatedExtension: '.command.g.dart');