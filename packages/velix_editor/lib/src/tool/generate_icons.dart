import 'dart:io';

void main() {
  final assetsDir = Directory('assets/icons');
  final outputFile = File('lib/svg_icons.dart');

  if (!assetsDir.existsSync()) {
    print('Assets folder does not exist: ${assetsDir.path}');
    exit(1);
  }

  final svgFiles = <File>[];
  _collectSvgFiles(assetsDir, svgFiles);

  final buffer = StringBuffer();

  buffer.writeln('// GENERATED FILE - DO NOT EDIT\n');
  buffer.writeln('class SvgIcons {');

  // constants
  for (final file in svgFiles) {
    final relativePath = file.path.replaceAll('\\', '/'); // normalize Windows paths
    final name = _makeConstantName(assetsDir, file);
    buffer.writeln('  static const String $name = "$relativePath";');
  }

  buffer.writeln('\n  // Registry for lookup by name');
  buffer.writeln('  static const Map<String, String> registry = {');
  for (final file in svgFiles) {
    final name = _makeConstantName(assetsDir, file);
    buffer.writeln('    "$name": $name,');
  }
  buffer.writeln('  };');

  buffer.writeln('  static String? get(String key) => registry[key];');

  buffer.writeln('}');

  outputFile.writeAsStringSync(buffer.toString());
  print('Generated ${outputFile.path} with ${svgFiles.length} icons.');
}

void _collectSvgFiles(Directory dir, List<File> out) {
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.svg')) {
      out.add(entity);
    }
  }
}

String _makeConstantName(Directory baseDir, File file) {
  var relative = file.path.replaceAll('\\', '/').replaceFirst('${baseDir.path}/', '');
  relative = relative.replaceAll('.svg', '');
  final parts = relative.split('/');
  return parts.join('_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
}
