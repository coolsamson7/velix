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
  Color convertTarget(String source) {
    source = source.replaceAll('#', ''); // remove hash if present
    if (source.length == 6) {
      // If only RGB is provided, add full opacity
      source = 'FF$source';
    }
    return Color(int.parse(source, radix: 16));
  }
}

@Dataclass()
class BorderStyleConvert extends Convert<BorderStyle,String> {
  @override
  String convertSource(BorderStyle source) {
    return source.name;
  }

  @override
  BorderStyle convertTarget(String source) {
    return BorderStyle.values.firstWhere((alignment) => alignment.name == source);
  }
}

@Dataclass()
class MainAxisAlignmentConvert extends Convert<MainAxisAlignment,String> {
  @override
  String convertSource(MainAxisAlignment source) {
    return source.name;
  }

  @override
  MainAxisAlignment convertTarget(String source) {
    return MainAxisAlignment.values.firstWhere((alignment) => alignment.name == source);
  }
}

@Dataclass()
class MainAxisSizeConvert extends Convert<MainAxisSize,String> {
  @override
  String convertSource(MainAxisSize source) {
    return source.name;
  }

  @override
  MainAxisSize convertTarget(String source) {
    return MainAxisSize.values.firstWhere((alignment) => alignment.name == source);
  }
}

@Dataclass()
class CrossAxisAlignmentConvert extends Convert<CrossAxisAlignment,String> {
  @override
  String convertSource(CrossAxisAlignment source) {
    return source.name;
  }

  @override
  CrossAxisAlignment convertTarget(String source) {
    return CrossAxisAlignment.values.firstWhere((alignment) => alignment.name == source);
  }
}

@Dataclass()
class FontWeightConvert extends Convert<FontWeight,int> {
  @override
  int convertSource(FontWeight source) {
    return source.value;
  }

  @override
  FontWeight convertTarget(int source) {
    return FontWeight.values.firstWhere((fw) => fw.value == source, orElse: () => FontWeight.normal,
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
enum ValueType {
  i18n,
  binding,
  value
}

@Dataclass()
class Value {
  // instance data

  @DeclareProperty()
  ValueType type;
  @DeclareProperty()
  String value;

  // constructor

  Value({this.type = ValueType.value, this.value = ""});
}


@Dataclass()
class Insets {
  @DeclareProperty(label: "editor:properties.insets.left")
  int left;
  @DeclareProperty(label: "editor:properties.insets.top")
  int top;
  @DeclareProperty(label: "editor:properties.insets.right")
  int right;
  @DeclareProperty(label: "editor:properties.insets.bottom")
  int bottom;

  Insets({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });
}

/*@Dataclass()
enum BorderStyle {
  solid,
  dashed,
  dotted
}*/

@Dataclass()
class Border {
  @DeclareProperty(label: "editor:properties.border.color")
  Color color;
  @DeclareProperty(label: "editor:properties.border.width")
  int width;
  @DeclareProperty(label: "editor:properties.border.style")
  BorderStyle style;

  // constructor

  Border({this.color=Colors.white, this.width=1, this.style=BorderStyle.solid});
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
