import 'package:flutter/material.dart' hide Dialog;
import 'package:flutter/services.dart';
import './dialog.dart';

class MessageDialog extends Dialog<MessageDialog> {
  // constructor

  MessageDialog(super._context);

  // fluent

  MessageDialog ok({String title = "Ok"}) {
    button(title, true, isDefault: true);

    return this;
  }

  MessageDialog cancel({String title = "Cancel"}) {
    button(title, null);

    return this;
  }

  MessageDialog okCancel() {
    return ok().cancel();
  }

  // override

  @override
  Future<V?> show<V>() {
    Icon icon;
    switch (dialogType) {
      case DialogType.info:
        icon = const Icon(Icons.info, color: Colors.blue, size: 48);
        break;
      case DialogType.warning:
        icon = const Icon(Icons.warning, color: Colors.orange, size: 48);
        break;
      case DialogType.error:
        icon = const Icon(Icons.error, color: Colors.red, size: 48);
        break;
      case DialogType.success:
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 48);
        break;
    }

    return showDialog(
      context: context,
      builder: (ctx) {
        return Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  final defaultButton = buttons.firstWhere(
                        (b) => b.isDefault,
                    orElse: () => buttons.first,
                  );
                  if (defaultButton.dismiss) Navigator.of(ctx).pop();

                  if (defaultButton.onPressed != null)
                    defaultButton.onPressed!();

                  return null;
                },
              ),
            },
            child: AlertDialog(
              title: Row(
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Expanded(child: Text(titleString ?? "")),
                ],
              ),
              content: Text(messageString ?? ""),
              actions: buttons
                  .map(
                    (b) => TextButton(
                  onPressed: () {
                    if (b.dismiss) Navigator.of(ctx).pop();
                    if(b.onPressed != null)
                      b.onPressed!();
                  },
                  style: b.isDefault
                      ? TextButton.styleFrom(
                    backgroundColor: Theme.of(ctx).primaryColor,
                    foregroundColor: Colors.white,
                  )
                      : null,
                  child: Text(b.label),
                ),
              ).toList(),
            ),
          ),
        );
      },
    );
  }
}


