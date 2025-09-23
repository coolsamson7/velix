import 'dart:async';
import 'package:flutter/foundation.dart';

typedef AsyncListener<T> = FutureOr<void> Function(T value);

class OrderedAsyncValueNotifier<T> extends ChangeNotifier {
  // instance data

  T _value;
  final List<AsyncListener<T>> _listeners = [];

  T get value => _value;

  set value(T newValue) {
    _value = newValue;
    // Don't call notifyListeners here directly; you can control it via update
  }

  // constructor

  OrderedAsyncValueNotifier(this._value);

  // public

  /// Adds an ordered async listener
  void addListenerAsync(AsyncListener<T> listener) {
    _listeners.add(listener);
  }

  /// Updates the value and triggers all listeners in order, waiting for async completion
  Future<void> updateValue(T newValue) async {
    _value = newValue;

    for (final listener in _listeners) {
      await Future.sync(() => listener(_value));
    }

    // After all listeners have completed, notify UI consumers

    notifyListeners();
  }
}
