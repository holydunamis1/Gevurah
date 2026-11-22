import 'package:flutter/widgets.dart';

import 'app_providers.dart';

/// Hands the providers to every screen below it.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.providers, required super.child});

  final AppProviders providers;

  static AppProviders of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context');
    return scope!.providers;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => providers != oldWidget.providers;
}
