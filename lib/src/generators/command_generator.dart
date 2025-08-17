import 'dart:async';

import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

class CommandGenerator extends Generator {
  // internal

  String getExtends(ClassElement2 classElement) {
    // Get the superclass element

    final superClassElement = classElement.supertype;

    if (superClassElement == null) {
      print('No superclass for ${classElement.displayName}');
      return "";
    }

    // Get the type arguments applied to the superclass
    final typeArguments = superClassElement.typeArguments;

    if (typeArguments.isEmpty) {
      print('Superclass has no generic arguments for ${classElement.displayName}');
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
      final commands = <MethodElement2>[];

      for (final method in clazz.methods2) {
        if (_isCommandMethod(method)) {
          commands.add(method);
        }
      }

      if (commands.isEmpty) continue;

      final fileName = buildStep.inputId.uri.pathSegments.last;

      // Add the part-of directive

      output.writeln("part of '$fileName';\n");

      final className = clazz.displayName;
      final mixinName = '${className}Commands';

      final type = getExtends(clazz);
      output.writeln('mixin $mixinName on CommandController<$type> {');

      // Generate initCommands

      output.writeln('  // override');
      output.writeln();

      output.writeln('  @override');
      output.writeln('  void initCommands() {');
      for (final method in commands) {
        final publicName = method.displayName.replaceFirst('_', '');
        final name = _getCommandAnnotation(method)!.peek('name')?.stringValue ??
            publicName;

        output.write('    addCommand("$name", _$publicName');

        // label

        final label = _getCommandAnnotation(method)!.peek('label')
            ?.stringValue ?? '';
        if (label.isNotEmpty)
          output.write(', label: \'$label\'');

        // i18n

        final i18n = _getCommandAnnotation(method)!.peek('i18n')?.stringValue ??
            '';
        if (i18n.isNotEmpty) {
          output.write(', i18n: \'$i18n\'');
        }

        // icon

        final iconObj = _getCommandAnnotation(method)!.peek('icon');
        if (iconObj != null && !iconObj.isNull) {
          final  dartObj = iconObj.objectValue;

          if (dartObj.variable != null) {
            // This works only if using analyzer >= 6.0.0 — otherwise need a cast
            final variable = dartObj.variable2!;
            final iconName = variable.name3; // add
            final iconType = variable.enclosingElement2?.name3; // CupertinoIcons
            output.write(', icon: $iconType.$iconName');
          }
          /* TODO else if (dartObj.toFunctionValue() is PropertyAccessorElement) {
            final accessor = dartObj.toFunctionValue() as PropertyAccessorElement;
            final variable = accessor.variable2;
            final iconName = variable.name;
            final iconType = variable.enclosingElement?.name;
            output.write(', icon: $iconType.$iconName');
          }*/
        }

        // lock

        final lock = _getCommandAnnotation(method)!.peek('lock');
        if (lock != null && !lock.isNull) {
          final revived = lock.revive(); // from source_gen
          //final typeName = revived.source?.fragment;   // e.g. 'LockType'
          final accessor = revived.accessor; // e.g. 'LockType.command'

          int dot = accessor.indexOf(".");
          var value = accessor.substring(dot + 1);

          if (value != "command")
            output.write(', lock: LockType.$value');
        }

        // done

        output.writeln(');');
      } // for

      output.writeln('  }');

      //  _<command>()...

      output.writeln();
      output.writeln('  // command declarations');
      output.writeln();

      for (final method in commands) {
        final publicName = method.displayName.replaceFirst('_', '');
        final signature = method.formalParameters.map((param) {
          final typeStr = param.type.getDisplayString(withNullability: false);
          return '$typeStr ${param.name3}';
        }).join(', ');

        // Use the method's own declared return type
        final returnType = method.returnType.getDisplayString(
            withNullability: false);

        output.writeln('  $returnType _$publicName($signature);');
      } // for

      // <command>(...)

      output.writeln();
      output.writeln('  // command bodies');
      output.writeln();

      for (final method in commands) {
        final publicName = method.displayName.replaceFirst('_', '');
        final signature = method.formalParameters.map((param) {
          final typeStr = param.type.getDisplayString(withNullability: false);
          return '$typeStr ${param.name3}';
        }).join(', ');
        final argList = method.typeParameters2.map((param) => param.name3).join(', ');

        final returnType = method.returnType.getDisplayString(
            withNullability: false);
        final isFuture = returnType.startsWith('Future');

        // If method returns Future<T>, make wrapper async and await execution
        final asyncKeyword = isFuture ? 'async ' : '';
        final awaitPrefix = isFuture ? 'await ' : '';

        // Add return if method actually returns something
        final needsReturn = returnType != 'void' &&
            returnType != 'Future<void>';
        final returnKeyword = needsReturn ? 'return ' : '';

        output.writeln('  $returnType $publicName($signature) $asyncKeyword{');
        output.writeln(
            '    ${returnKeyword}${awaitPrefix}execute("$publicName", [$argList]);');
        output.writeln('  }');
      } // for

      output.writeln('}');
    }



    return output.toString();
  }

  bool _isCommandMethod(MethodElement2 method) {
    return method.metadata2.annotations.any((m) =>
    m.computeConstantValue()?.type?.getDisplayString() == 'Command');
  }

  ConstantReader? _getCommandAnnotation(MethodElement2 method) {
    for (final meta in method.metadata2.annotations) {
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