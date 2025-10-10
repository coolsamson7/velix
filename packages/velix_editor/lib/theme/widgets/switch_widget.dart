import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_ui/databinding/valued_widget.dart';
import 'package:velix_ui/databinding/widgets/common/switch.dart';

import '../../metadata/widgets/switch.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class SwitchWidgetBuilder extends WidgetBuilder<SwitchWidgetData> {
  // constructor

  SwitchWidgetBuilder() : super(name: "switch");

  // override

  @override
  Widget create(SwitchWidgetData data, Environment environment, BuildContext context) {
    var widgetContext = Provider.of<WidgetContext>(context);

    var mapper = widgetContext.formMapper;
    var instance = widgetContext.instance;

    var adapter = environment.get<SwitchAdapter>();

    var typeProperty = mapper.computeProperty(TypeDescriptor.forType(instance.runtimeType), data.databinding!);

    var result = Switch(
      padding: data.padding?.edgeInsets(),
      value: mapper.getValue(typeProperty),
      onChanged: (bool newValue) {
        (context as Element).markNeedsBuild();

        mapper.notifyChange(property: typeProperty, value: newValue);
      },
    );

    mapper.map(property: typeProperty, widget: result, adapter: adapter);

    return result;
  }
}


@Injectable()
class EditSwitchWidgetBuilder extends WidgetBuilder<SwitchWidgetData> {
  // constructor

  EditSwitchWidgetBuilder() : super(name: "switch", edit: true);

  // override

  @override
  Widget create(SwitchWidgetData data, Environment environment, BuildContext context) {
    // In edit mode, make the text field non-interactive
    return IgnorePointer(
      ignoring: true,
      child: Switch(
        value: false,
        onChanged: (bool newValue) {},
      ),
    );
  }
}