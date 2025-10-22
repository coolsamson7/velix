import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

///  A [ValuedWidgetAdapter] for a [Switch]
@WidgetAdapter(platforms: [TargetPlatform.android])
@Injectable()
class DropDownAdapter extends AbstractValuedWidgetAdapter<DropdownButton> {
  // constructor

  DropDownAdapter() : super('dropdown', [TargetPlatform.android]);

  // override

  @override
  Widget build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    final value = mapper.getValue(property);

    // Expected: args["items"] is List<String> or List<Map<String, dynamic>>
    final items = (args["items"] ?? <dynamic>[]).map<DropdownMenuItem>((item) {
      if (item is Map<String, dynamic>) {
        return DropdownMenuItem(
          value: item["value"],
          child: Text(item["label"] ?? item["value"].toString()),
        );
      } else {
        return DropdownMenuItem(value: item, child: Text(item.toString()));
      }
    }).toList();

    final dropdown = DropdownButton(
      key: ValueKey("$name:${property.path}"),
      value: value,
      items: items,
      isExpanded: args["expanded"] ?? true,
      hint: args["hint"] != null ? Text(args["hint"]) : null,
      onChanged: (newValue) {
        (context as Element).markNeedsBuild();
        mapper.notifyChange(property: property, value: newValue);
      },
    );

    mapper.map(property: property, widget: dropdown, adapter: this);

    return dropdown;
  }

  @override
  dynamic getValue(DropdownButton widget) {
    return widget.value;
  }

  @override
  void setValue(DropdownButton widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}