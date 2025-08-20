import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'valued_widget.dart';
import 'form_mapper.dart';
import 'package:intl/intl.dart';

@WidgetAdapter()
class DatePickerAdapter extends AbstractValuedWidgetAdapter<FormField<DateTime>> {
  // constructor

  DatePickerAdapter() : super('date', '');

  // override

  @override
  FormField<DateTime> build({
    required BuildContext context,
    required FormMapper mapper,
    required String path,
    Map<String, dynamic> args = const {},
  }) {
    var typeProperty = mapper.computeProperty(mapper.type, path);

    DateTime? initialValue = typeProperty.get(mapper.instance, ValuedWidgetContext(mapper: mapper));

    final DateFormat dateFormat = args['dateFormat'] ?? DateFormat.yMd();

    return FormField<DateTime>(
      key: ValueKey(path),
      initialValue: initialValue,
      validator: (date) {
        try {
          typeProperty.validate(date);
          return null;
        } catch (e) {
          // You may want to use your translation manager or error formatter here
          return e.toString();
        }
      },
      builder: (FormFieldState<DateTime> state) {
        String displayText = state.value != null ? dateFormat.format(state.value!) : 'Tap to select date';

        return InkWell(
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode()); // dismiss keyboard if any

            final pickedDate = await showDatePicker(
              context: context,
              initialDate: state.value ?? DateTime.now(),
              firstDate: args['firstDate'] ?? DateTime(1900),
              lastDate: args['lastDate'] ?? DateTime(2100),
            );

            if (pickedDate != null) {
              state.didChange(pickedDate);
              mapper.notifyChange(path: path, value: pickedDate);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: args['label'] ?? 'Select Date',
              errorText: state.errorText,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            child: Text(displayText),
          ),
        );
      },
      onSaved: (date) {
        // Save logic if workflow requires
      },
    );
  }

  @override
  dynamic getValue(FormField<DateTime> widget) {
    // Usually, you get the current selected date value from the FormField's state
    // This requires a global key to access state, so return null here or override if you manage keys
    return null;
  }

  @override
  void setValue(FormField<DateTime> widget, dynamic value, ValuedWidgetContext context) {
    // To implement if you keep a reference to state, else noop
  }
}

extension DatePickerFormFieldExtension on FormMapper {
  Widget date({
    required String path,
    required BuildContext context,
    DateTime? firstDate,
    DateTime? lastDate,
    String? label,
    DateFormat? dateFormat,
  }) {
    Map<String, dynamic> args = {
      if (firstDate != null) 'firstDate': firstDate,
      if (lastDate != null) 'lastDate': lastDate,
      if (label != null) 'label': label,
      if (dateFormat != null) 'dateFormat': dateFormat,
    };

    return bind('date', path: path, context: context, args: args);
  }
}
