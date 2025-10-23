import 'dart:ui';

import 'package:flutter/material.dart' show BuildContext;

import 'input_dialog.dart';
import 'message_dialog.dart';

class DialogButton {
  // instance data

  final dynamic value;
  final String label;
  final VoidCallback? onPressed;
  final bool dismiss;
  final bool isDefault;

  // constructor

  DialogButton(this.label, this.value,
      {this.dismiss = true, this.isDefault = false, this.onPressed});
}

enum DialogType { info, warning, error, success }

abstract class Dialog<T extends Dialog<T>> {
  // static

  static InputDialog inputDialog(BuildContext context) => InputDialog(context);

  static MessageDialog messageDialog(BuildContext context) => MessageDialog(context);

  // instance data

  final BuildContext context;
  String? titleString;
  String? messageString;
  DialogType dialogType = DialogType.info;
  final List<DialogButton> buttons = [];

  // constructor

  Dialog(this.context);

  // fluent

  T title(String title) {
    title = title;

    return this as T;
  }

  T message(String message) {
    messageString = message;

    return this as T;
  }

  T type(DialogType type) {
    dialogType = type;

    return this as T;
  }

  T button(
      String label,
      dynamic value,
      {
        VoidCallback? onPressed,
        bool dismiss = true,
        bool isDefault = false,
      }) {
    buttons.add(DialogButton(label, value, onPressed: onPressed, dismiss: dismiss, isDefault: isDefault));

    return this as T;
  }

  Future<V?> show<V>();
}