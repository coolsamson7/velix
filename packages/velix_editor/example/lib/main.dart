import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:velix/velix.dart';
import 'package:velix_di/velix_di.dart';
import 'package:velix_editor/editor_module.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_editor/metadata/widget_data.dart';
import 'package:velix_i18n/velix_i18n.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';
import 'package:velix_ui/velix_ui.dart';

import 'main.types.g.dart';
import 'application.dart';

class VelixTranslator extends Translator {
  // constructor

  VelixTranslator() {
    Translator.instance = this;
  }

  // implement

  @override
  String translate(String key, {String? defaultValue, Map<String, dynamic>  args = const {}}) {
    return I18N.tr(key, defaultValue: defaultValue, args: args);
  }
}

@Module(imports: [EditorModule])
class ApplicationModule {
}

void main() async {
  // flutter

  ValuedWidget.platform = TargetPlatform.android;

  WidgetsFlutterBinding.ensureInitialized();

  // TEST

  enumeration<MainAxisAlignment>(
      name: 'asset:velix_mapper/test/model.dart.MainAxisAlignment',
      values: MainAxisAlignment.values
  );

  enumeration<CrossAxisAlignment>(
      name: 'asset:velix_mapper/test/model.dart.MainAxisAlignment',
      values: CrossAxisAlignment.values
  );

  enumeration<MainAxisSize>(
      name: 'asset:velix_mapper/test/model.dart.MainAxisSize',
      values: MainAxisSize.values
  );

  // tracer

  Tracer(
      isEnabled: true,
      trace: ConsoleTrace("%d [%l] %p: %m [%f]"), // d(ate), l(evel), p(ath), m(message), f(ile)
      paths: {
        "": TraceLevel.off,
        "i18n": TraceLevel.full,
        "editor": TraceLevel.full,
        "di": TraceLevel.full
      });

  // bootstrap types

  Velix.bootstrap;
  EditorModule.boot; // this sucks

  registerTypes();

  // configure json stuff

  JSON(
      validate: false,
      converters: [
        ColorConvert(),
        FontWeightConvert(),
        FontStyleConvert(),
        Convert<DateTime,String>(
            convertSource: (value) => value.toIso8601String(),
            convertTarget: (str) => DateTime.parse(str)
        )
      ],
      factories: [
        Enum2StringFactory()
      ]);

  // translation

  VelixTranslator();

  TypeViolationTranslationProvider();

  var localeManager = LocaleManager(Locale('en'), supportedLocales: [Locale('en'), Locale('de')]);

  var i18n = I18N(
      fallbackLocale: Locale("en"),
      localeManager: localeManager,
      loader: AssetTranslationLoader(
        namespacePackageMap: {
          "validation": "velix",
          "editor": "velix_editor"
        }
      ),
      missingKeyHandler: (key) {
        print("missing i18n: $key");
        return '##$key##';
        },
      preloadNamespaces: ["validation", "editor"]
  );

  await i18n.load();

  // load json

  final jsonString = await rootBundle.loadString('assets/widgets.json');

  var json = jsonDecode(jsonString);

  var widget = JSON.deserialize<WidgetData>(json);

  // boot environment

  var environment = Environment(forModule: ApplicationModule);

  // load namespaces

  runApp(EditorApp(
      environment: environment,
      i18n: i18n,
      localeManager: localeManager,
      widgets: [widget]
  ));
}

