
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:velix/util/tracer.dart';
import '../i18n.dart';

class AssetTranslationLoader implements TranslationLoader {
  // instance data

  final String basePath;
  final Map<String, String> namespacePackageMap;

  // constructor

  /// [basePath] is the folder where your locales live, e.g. 'assets/locales'
  AssetTranslationLoader({this.basePath = 'assets/locales',  Map<String, String>? namespacePackageMap}) : namespacePackageMap = namespacePackageMap ?? {};

  // override

  @override
  Future<Map<String, dynamic>> load(List<Locale> locales, String namespace) async {
    final packageName = namespacePackageMap[namespace];
    String path;

    Map<String, dynamic> mergedTranslations = {};

    for (var locale in locales) {
      if (packageName != null) {
        path = 'packages/$packageName/$basePath/$locale/$namespace.json';
      }
      else {
        path = '$basePath/$locale/$namespace.json';
      }

      try {
        final jsonString = await rootBundle.loadString(path);

        if ( Tracer.enabled)
          Tracer.trace("i18n", TraceLevel.high, "load $path");

        final Map<String, dynamic> map = json.decode(jsonString);

        map.forEach((key, value) {
          mergedTranslations.putIfAbsent(key, () => value);
        });
      }
      catch (e) {
        // Could not load the file; return empty map or handle missing file

        if ( !e.toString().startsWith("Unable to load"))
          debugPrint('exception while loading translations from $path, error: $e');
      }
    } // for

    return mergedTranslations;
  }
}