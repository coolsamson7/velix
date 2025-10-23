import 'package:flutter/material.dart' hide Dialog;
import 'package:flutter/services.dart';

import './dialog.dart';

class _DialogInput {
  final String label;
  final TextEditingController controller;
  final bool obscureText;

  _DialogInput({required this.label, required this.controller, this.obscureText = false});
}

class InputDialog extends Dialog<InputDialog> {
  // instance data

  final List<_DialogInput> _inputs = [];

  // constructor

  InputDialog(super.context);

  // fluent

  InputDialog inputField(
      String label, {
        String? initialValue,
        TextEditingController? controller,
        bool obscureText = false,
      }) {
    _inputs.add(_DialogInput(
      label: label,
      controller: controller ?? TextEditingController(text: initialValue),
      obscureText: obscureText,
    ));
    return this;
  }

  // override

  @override
  Future<T?> show<T>() {
    return showDialog<T>(
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
                  if (defaultButton.dismiss)
                    Navigator.of(ctx).pop(defaultButton.value as T);

                  if( defaultButton.onPressed != null)
                    defaultButton.onPressed!();

                  return null;
                },
              ),
            },
            child: AlertDialog(
              title: titleString != null ? Text(titleString!) : null,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (messageString != null) Text(messageString!),
                  ..._inputs.map(
                        (input) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: input.controller,
                        obscureText: input.obscureText,
                        decoration: InputDecoration(
                          labelText: input.label,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          final defaultButton = buttons.firstWhere(
                                (b) => b.isDefault,
                            orElse: () => buttons.first,
                          );
                          if (defaultButton.dismiss)
                            Navigator.of(ctx).pop(defaultButton.value as T);

                          if ( defaultButton.onPressed != null)
                            defaultButton.onPressed!();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: buttons
                  .map(
                    (b) => TextButton(
                  onPressed: () {
                    if (b.dismiss) Navigator.of(ctx).pop(b.value);

                    if (b.onPressed != null)
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
              )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  String getInputValue(String label) {
    return _inputs.firstWhere((i) => i.label == label).controller.text;
  }
}