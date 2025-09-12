import 'dart:convert';
import 'dart:io';

import '../../di/di.dart';
import '../configuration.dart';

@Injectable(factory: false)
class JsonFileConfigurationSource extends ConfigurationSource {
  // instance data

  final String filePath;

  // constructor

  JsonFileConfigurationSource(this.filePath);

  // override

  @override
  Map<String, dynamic> load() {
    try {
      // Read file contents
      final file = File(filePath);
      if (!file.existsSync()) {
        throw ConfigurationException('Configuration file not found: $filePath');
      }

      final contents = file.readAsStringSync();
      if (contents.trim().isEmpty) {
        return <String, dynamic>{};
      }

      // parse JSON

      final dynamic parsed = jsonDecode(contents);

      if (parsed is! Map<String, dynamic>) {
        throw ConfigurationException('Configuration file must contain a JSON object: $filePath');
      }

      return parsed;
    }
    on FileSystemException catch (e) {
      throw ConfigurationException('Failed to read configuration file: $filePath', e);
    }
    on FormatException catch (e) {
      throw ConfigurationException('Invalid JSON in configuration file: $filePath', e);
    }
    catch (e) {
      throw ConfigurationException('Unexpected error loading configuration: $filePath', e as Exception?);
    }
  }
}