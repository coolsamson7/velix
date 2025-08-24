import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/i18n/locale.dart';

import 'main.type_registry.g.dart';

void main() {
  group('i18n', () {
    WidgetsFlutterBinding.ensureInitialized();

    // register types

    registerAllDescriptors();

    test('translate', () async {

      // start in en

      final localeManager = LocaleManager(Locale('en'));

      I18n(
        localeManager: localeManager,
        loader: AssetTranslationLoader(),
        missingKeyHandler: (key) => '##$key##',
      );

      // load namespaces

      await I18n.instance.loadNamespaces(["velix"]);

      // test

      print('velix:validation.int.lessThan'.tr({'lessThan': 1}));

      // switch to de

      localeManager.locale = Locale('de');

      // Wait for reload TODO

      await Future.delayed(Duration(milliseconds: 50));

      print('velix:validation.int.lessThan'.tr({'lessThan': 1}));
    });
  });
}