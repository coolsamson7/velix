import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velix_i18n/i18n/i18n.dart';
import 'package:velix_i18n/i18n/loader/asset_loader.dart';
import 'package:velix_i18n/i18n/locale.dart';

Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

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

    // Wait for reload... only required in this sample test of course

    await Future.delayed(Duration(milliseconds: 50));

    print('velix:validation.int.lessThan'.tr({'lessThan': 1}));
}