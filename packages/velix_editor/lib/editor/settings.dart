import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SettingsManager {
  // instance data

  late Directory dir;
  late File file;
  Map<String, dynamic> settings = {};
  bool initialized = false;

  // constructor

  SettingsManager() {
    init();
  }

  // public

  Future<void> init() async {
    if (!initialized) {
      dir = await getApplicationSupportDirectory();

      file = File('${dir.path}/settings.json');
      if (await file.exists()) {
        settings = jsonDecode(await file.readAsString());
      }
      else {
        await file.writeAsString(jsonEncode(settings));
      }

      initialized = true;
    }
  }

  Future<void> flush() async {
    await init();
    await file.writeAsString(jsonEncode(settings));
  }

  // public

  T set<T>(String key, T value) {
    settings[key] = value;

    return value;
  }

  T get<T>(String key, {T? defaultValue}) {
    var result = settings[key];
    if ( result != null)
      return result as T;
    else  {
      return set<T>(key, defaultValue!);
    }
  }
}