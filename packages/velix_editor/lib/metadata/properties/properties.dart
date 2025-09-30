import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/mapper.dart';

import '../../property_panel/editor/font_editor.dart';
import '../annotations.dart';


@Dataclass()
class ColorConvert extends Convert<Color,String> {
  @override
  String convertSource(Color source) {
    return source.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  @override
  Color convertTarget(String value) {
    value = value.replaceAll('#', ''); // remove hash if present
    if (value.length == 6) {
      // If only RGB is provided, add full opacity
      value = 'FF$value';
    }
    return Color(int.parse(value, radix: 16));
  }
}
@Dataclass()
class FontWeightConvert extends Convert<FontWeight,int> {
  @override
  int convertSource(FontWeight source) {
    return source.value;
  }

  @override
  FontWeight convertTarget(int value) {
    return FontWeight.values.firstWhere((fw) => fw.value == value, orElse: () => FontWeight.normal,
    );
  }
}

@Dataclass()
class FontStyleConvert extends Convert<FontStyle,String> {
  @override
  String convertSource(FontStyle source) {
    return source.name;
  }

  @override
  FontStyle convertTarget(String source) {
    return FontStyle.values.firstWhere((value) => value.name == source);
  }
}

@Dataclass()
class Padding {
  @DeclareProperty(label: "editor:properties.padding.left")
  int left;
  @DeclareProperty(label: "editor:properties.padding.top")
  int top;
  @DeclareProperty(label: "editor:properties.padding.right")
  int right;
  @DeclareProperty(label: "editor:properties.padding.bottom")
  int bottom;

  Padding({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });
}

@Dataclass()
class Font {
  @DeclareProperty(label: "editor:properties.font.family", editor: FontEditorBuilder)
  String family;

  @DeclareProperty(label: "editor:properties.font.weight")
  FontWeight weight;

  @DeclareProperty(label: "editor:properties.font.style")
  FontStyle style;

  @DeclareProperty(label: "editor:properties.font.size")
  int size;

  Font({this.weight = FontWeight.normal, this.style = FontStyle.normal, this.family = "Arial", this.size = 16});
}
