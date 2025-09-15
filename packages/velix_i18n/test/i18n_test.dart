import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_i18n/i18n/loader/asset_loader.dart';
import 'package:velix_i18n/i18n/locale.dart';


void main() {
  group('i18n', () {
    WidgetsFlutterBinding.ensureInitialized();

    // register types

    //registerAllDescriptors();

    test('translate', () async {

      // start in en

      final localeManager = LocaleManager(Locale('en', "EN"), supportedLocales: [Locale('en'), Locale('de')]);

      I18N(
        localeManager: localeManager,
        fallbackLocale: Locale("en", "EN"),
        loader: AssetTranslationLoader(
            namespacePackageMap: {
              "validation": "velix"
            }),

        missingKeyHandler: (key) => '##$key##',
      );

      // load namespaces

      await I18N.instance.loadNamespaces(["validation"]);

      // test

      print('validation:currency.type'.tr({'currency': 11, 'symbol': 'EUR'}));
      print('validation:int.lessThan'.tr({'lessThan': 1}));

      // switch to de

      localeManager.locale = Locale('de');

      // Wait for reload TODO

      await Future.delayed(Duration(milliseconds: 50));

      print('validation:int.lessThan'.tr({'lessThan': 1}));
    });
  });
}