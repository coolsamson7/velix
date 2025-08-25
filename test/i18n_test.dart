import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix/i18n/i18n.dart';
import 'package:velix/i18n/loader/asset_loader.dart';
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

      I18N(
        localeManager: localeManager,
        loader: AssetTranslationLoader(),
        missingKeyHandler: (key) => '##$key##',
      );

      // load namespaces

      await I18N.instance.loadNamespaces(["velix"]);

      // test

      print('velix:validation.currency.type'.tr({'currency': 11, 'symbol': 'EUR'}));

      print('velix:validation.int.lessThan'.tr({'lessThan': 1}));

      // switch to de

      localeManager.locale = Locale('de');

      // Wait for reload TODO

      await Future.delayed(Duration(milliseconds: 50));

      print('velix:validation.int.lessThan'.tr({'lessThan': 1}));
    });
  });
}