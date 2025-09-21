import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';

import '../annotations.dart';
import '../widget_data.dart';

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
class PaddingConvert extends Convert<Padding,Map<String,dynamic>> {
  @override
  Map<String,dynamic> convertSource(Padding source) {
    return {};
  }

  @override
  Padding convertTarget(Map<String,dynamic> source) {
    return Padding(); // TODO
  }
}

@Dataclass()
class Padding {
  int left;
  int top;
  int right;
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
  @DeclareProperty()
  @Json(converter: FontWeightConvert)
  FontWeight weight;

  @DeclareProperty()
  @Json(converter: FontStyleConvert)
  FontStyle style;

  @DeclareProperty()
  int size;

  Font({this.weight = FontWeight.normal, this.style = FontStyle.normal, this.size = 16});
}

@Dataclass()
@DeclareWidget(name: "button", group: "Widgets", icon: Icons.text_fields)
@JsonSerializable(discriminator: "button")
class ButtonWidgetData extends WidgetData {
  // instance data

  @DeclareProperty(group: "General")
  String label;
  @DeclareProperty(group: "Font Properties")
  Font? font;
  @DeclareProperty(group: "Layout Properties")
  Padding? padding;

  // constructor

  ButtonWidgetData({super.type = "button", super.children = const [], required this.label, this.font, this.padding});
}