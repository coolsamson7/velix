import 'package:flutter/material.dart' show CrossAxisAlignment, MainAxisAlignment, MainAxisSize, BorderStyle;
import 'package:velix_di/di/di.dart';

import '../enum_editor.dart';

@Injectable()
class CrossAxisAlignmentBuilder extends AbstractEnumBuilder<CrossAxisAlignment> {
  CrossAxisAlignmentBuilder():super(values: CrossAxisAlignment.values);
}


@Injectable()
class MainAxisAlignmentBuilder extends AbstractEnumBuilder<MainAxisAlignment> {
  MainAxisAlignmentBuilder():super(values: MainAxisAlignment.values);
}


@Injectable()
class MainAxisSizeBuilder extends AbstractEnumBuilder<MainAxisSize> {
  MainAxisSizeBuilder():super(values: MainAxisSize.values);
}

@Injectable()
class BorderStyleBuilder extends AbstractEnumBuilder<BorderStyle> {
  BorderStyleBuilder():super(values: BorderStyle.values);
}
