import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
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
  @DeclareProperty(label: "editor:properties.font.weight")
  FontWeight weight;

  @DeclareProperty(label: "editor:properties.font.style")
  FontStyle style;

  @DeclareProperty(label: "editor:properties.font.size")
  int size;

  Font({this.weight = FontWeight.normal, this.style = FontStyle.normal, this.size = 16});
}
