import 'package:velix_ui/velix_ui.dart';
import 'package:velix_ui/velix_ui.dart';

import 'checkbox.dart';
import 'datepicker.dart';
import 'text.dart';
import 'switch.dart';
import 'slider.dart';


void registerMaterialWidgets() {
  DatePickerAdapter();
  CheckboxAdapter();
  SwitchAdapter();
  SliderAdapter();
  TextFormFieldAdapter();
}
