import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';

import '../annotations.dart';


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
  @DeclareProperty(i18n: "editor:properties.padding.left")
  int left;
  @DeclareProperty(i18n: "editor:properties.padding.top")
  int top;
  @DeclareProperty(i18n: "editor:properties.padding.right")
  int right;
  @DeclareProperty(i18n: "editor:properties.padding.bottom")
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
  @DeclareProperty(i18n: "editor:properties.font.weight")
  FontWeight weight;

  @DeclareProperty(i18n: "editor:properties.font.style")
  FontStyle style;

  @DeclareProperty(i18n: "editor:properties.font.size")
  int size;

  Font({this.weight = FontWeight.normal, this.style = FontStyle.normal, this.size = 16});
}
