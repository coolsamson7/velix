import 'package:flutter/material.dart' show CrossAxisAlignment, MainAxisAlignment, MainAxisSize, BorderStyle;
import 'package:velix_di/di/di.dart';

import '../enum_editor.dart';

@Injectable()
class CrossAxisAlignmentBuilder extends AbstractEnumBuilder<CrossAxisAlignment> {
}


@Injectable()
class MainAxisAlignmentBuilder extends AbstractEnumBuilder<MainAxisAlignment> {
}


@Injectable()
class MainAxisSizeBuilder extends AbstractEnumBuilder<MainAxisSize> {
}

@Injectable()
class BorderStyleBuilder extends AbstractEnumBuilder<BorderStyle> {
}
