
import 'package:velix/databinding/slider_adapter.dart';

import 'checkbox_adapter.dart';
import 'datepicker_adapter.dart';
import 'switch_adapter.dart';
import 'text_adapter.dart';

void registerWidgets() {
  DatePickerAdapter();
  CheckboxAdapter();
  SwitchAdapter();
  SliderAdapter();
  TextFieldAdapter();
  TextFormFieldAdapter();
}
