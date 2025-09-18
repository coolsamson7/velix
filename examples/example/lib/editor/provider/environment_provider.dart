import 'package:flutter/material.dart';
import 'package:velix_di/di/di.dart';

class EnvironmentProvider extends InheritedWidget {
  final Environment environment;

  const EnvironmentProvider({
    Key? key,
    required this.environment,
    required Widget child,
  }) : super(key: key, child: child);

  static Environment of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<EnvironmentProvider>();
    return provider!.environment;
  }

  @override
  bool updateShouldNotify(EnvironmentProvider oldWidget) {
    return environment != oldWidget.environment;
  }
}