import 'package:flutter/material.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_mapper/mapper/json.dart';
import 'package:velix_mapper/mapper/mapper.dart';

import '../annotations.dart';
import '../widget_data.dart';

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
class Font {
  @DeclareProperty()
  @Json(converter: FontWeightConvert)
  FontWeight weight;

  @DeclareProperty()
  @Json(converter: FontStyleConvert)
  FontStyle style;

  @DeclareProperty()
  int size;

  Font({required this.weight, required this.style, required this.size});
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

  // constructor

  ButtonWidgetData({super.type = "button", super.children = const [], required this.label, required this.font});
}