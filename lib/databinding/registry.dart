
import 'switch_adapter.dart';
import 'text_adapter.dart';
import 'valued_widget.dart';

void registerWidgets() {
  ValuedWidget.register(CupertinoSwitchAdapter());
  ValuedWidget.register(TextFieldAdapter());
  ValuedWidget.register(TextFormFieldAdapter());
}
