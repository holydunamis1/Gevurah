import 'package:flutter/foundation.dart';

import '../core/models/settings_model.dart';
import 'settings_provider.dart';

/// The theme choice, kept in step with the saved settings.
class ThemeProvider extends ValueNotifier<ThemeChoice> {
  ThemeProvider(this._settings) : super(_settings.settings.themeChoice) {
    _settings.addListener(_sync);
  }

  final SettingsProvider _settings;

  void _sync() => value = _settings.settings.themeChoice;

  Future<bool> choose(ThemeChoice choice) => _settings.update((SettingsModel s) => s.copyWith(themeChoice: choice));

  /// Whether to draw dark, given what the phone is using.
  bool isDark(bool platformIsDark) {
    switch (value) {
      case ThemeChoice.system:
        return platformIsDark;
      case ThemeChoice.light:
        return false;
      case ThemeChoice.dark:
        return true;
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_sync);
    super.dispose();
  }
}
