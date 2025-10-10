import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix_editor/util/assets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Assets.init();

  group('assets', () {
    // register types

    test('preload', () async {
      await Assets.assets().preload<String>("locales/en");

      for (var item in Assets.assets().list("locales/en"))
        print(item.get<String>());
    });

    test('preload transform', () async {
      await Assets.assets().preloadTransform<String, Map<String,dynamic>>(prefix: "locales/en", transform: (src) => jsonDecode(src));

      for (var item in Assets.assets().list("locales/en"))
        print(item.get<Map<String,dynamic>>());
    });

    test('list', () async {
      for (var item in Assets.assets().list("locales/en"))
        print(await item.load<String>());
    });
  });
}