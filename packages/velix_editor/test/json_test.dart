import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:velix_editor/editor.types.g.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_editor/metadata/widgets/button.dart';
import 'package:velix_editor/metadata/widgets/container.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';

void main() {
  group('json', () {
    // register types

    registerEditorTypes();

    JSON(
        validate: false,
        converters: [
          BorderStyleConvert(),
          MainAxisSizeConvert(),
          MainAxisAlignmentConvert(),
          CrossAxisAlignmentConvert(),
          ColorConvert(),
          FontWeightConvert(),
          FontStyleConvert(),

          Convert<DateTime, String>(
              convertSource: (value) => value.toIso8601String(),
              convertTarget: (str) => DateTime.parse(str))
        ],
        factories: [
          Enum2StringFactory()
        ]);

    test('serialize container', () {
      var input = ContainerWidgetData(
          children: [
            ButtonWidgetData(
              label: "zwei",
              padding: Insets(left: 1, top: 1, right: 1, bottom: 1),
              font: Font(
                  weight: FontWeight.normal,
                  style: FontStyle.normal,
                  size: 16
              )
          )
          ]
      );

      var json = JSON.serialize(input);

      var type = json["children"][0]["type"];
      expect(type, equals("button"));
    });

    test('serialize button', () {
      var input = ButtonWidgetData(
          label: "zwei",
          padding: Insets(left: 1, top: 1, right: 1, bottom: 1),
          font: Font(
              weight: FontWeight.normal,
              style: FontStyle.normal,
              size: 16
          )
      );

      var json = JSON.serialize(input);

      var style = json["font"]["style"];
      expect(style.runtimeType, equals(String));
      expect(style, equals("normal"));
    });

    test('deserialize button', () {
      var input = ButtonWidgetData(
          label: "zwei",
          onClick: "click()",
          //padding: Insets(left: 1, top: 1, right: 1, bottom: 1),
          font: Font(
              weight: FontWeight.normal,
              style: FontStyle.normal,
              size: 16
          )
      );


      var json = JSON.serialize(input);
      var result = JSON.deserialize<ButtonWidgetData>(json);

      print(result);

      //final isEqual = TypeDescriptor.deepEquals(input, result);
      //expect(isEqual, isTrue);
    });
  });
}