import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:velix/databinding/valued_widget.dart';

import '../../../util/collections.dart';
import '../../form_mapper.dart';

@WidgetAdapter()
class DatePickerAdapter extends AbstractValuedWidgetAdapter<FormField<DateTime>> {
  DatePickerAdapter() : super('date', 'iOS');

  @override
  FormField<DateTime> build({
    required BuildContext context,
    required FormMapper mapper,
    required String path,
    required Keywords args}) {
    var typeProperty = mapper.computeProperty(mapper.type, path);
    DateTime? initialValue = typeProperty.get(mapper.instance, ValuedWidgetContext(mapper: mapper));

    final DateFormat dateFormat = args['dateFormat'] ?? DateFormat.yMd();
    final DateTime minDate = args['firstDate'] ?? DateTime(1900);
    final DateTime maxDate = args['lastDate'] ?? DateTime(2100);

    return FormField<DateTime>(
      key: ValueKey(path),
      initialValue: initialValue,
      validator: (date) {
        try {
          typeProperty.validate(date);
          return null;
        } catch (e) {
          return e.toString();
        }
      },
      builder: (FormFieldState<DateTime> state) {
        String displayText = state.value != null ? dateFormat.format(state.value!) : 'Tap to select date';

        void _showCupertinoDatePicker() {
          showCupertinoModalPopup(
            context: context,
            builder: (_) => Container(
              height: 250,
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
                minimumDate: minDate,
                maximumDate: maxDate,
                initialDateTime: state.value ?? DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  state.didChange(newDate);
                  mapper.notifyChange(path: path, value: newDate);
                },
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            // Dismiss keyboard if visible
            FocusScope.of(context).requestFocus(FocusNode());
            _showCupertinoDatePicker();
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: (state.hasError) ? CupertinoColors.systemRed.resolveFrom(context) : CupertinoColors.separator.resolveFrom(context),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayText,
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                ),
                Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ],
            ),
          ),
        );
      },
      onSaved: (date) {
        // if you need to save
      },
    );
  }

  @override
  dynamic getValue(FormField<DateTime> widget) {
    return null; // override if you track state
  }

  @override
  void setValue(FormField<DateTime> widget, dynamic value, ValuedWidgetContext context) {
    // override if you track state
  }
}

// Extension to use in FormMapper as before
extension DatePickerFormFieldExtension on FormMapper {
  Widget date({
    required String path,
    required BuildContext context,
    DateTime? firstDate,
    DateTime? lastDate,
    String? label,
    DateFormat? dateFormat,
  }) {
    return bind('date', path: path, context: context, args: Keywords({
      'firstDate': firstDate,
      'lastDate': lastDate,
      'dateFormat': dateFormat
    }));
  }
}
