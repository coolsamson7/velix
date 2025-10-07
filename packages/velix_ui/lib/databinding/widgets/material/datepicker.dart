import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'package:velix/velix.dart';
import 'package:velix_di/di/di.dart';

import '../../valued_widget.dart';
import '../../form_mapper.dart';

@WidgetAdapter(platforms: [TargetPlatform.android])
@Injectable()
class MaterialDatePickerAdapter extends AbstractValuedWidgetAdapter<FormField<DateTime>> {
  MaterialDatePickerAdapter() : super('date', [TargetPlatform.android]);

  @override
  FormField<DateTime> build({
    required BuildContext context,
    required FormMapper mapper,
    required TypeProperty property,
    required Keywords args}) {
    DateTime? initialValue = mapper.getValue(property);

    final DateFormat dateFormat = args['dateFormat'] ?? DateFormat.yMd();
    final DateTime minDate = args['firstDate'] ?? DateTime(1900);
    final DateTime maxDate = args['lastDate'] ?? DateTime(2100);

    var result = FormField<DateTime>(
      key: ValueKey(property.path),
      initialValue: initialValue,
      validator: (date) {
        try {
          property.validate(date);
          return null;
        }
        catch (e) {
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
                  mapper.notifyChange(property: property, value: newDate);
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

    // new mapping

    mapper.map(property: property, widget: result, adapter: this);

    // done

    return result;
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