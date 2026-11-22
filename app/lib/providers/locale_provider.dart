import 'package:flutter/foundation.dart';

import '../core/models/settings_model.dart';
import '../core/verses/verse_repository.dart';
import 'settings_provider.dart';

/// The app language: the player's choice if they made one, otherwise the
/// phone's, otherwise English. The value is always one of the 11 languages.
class LocaleProvider extends ValueNotifier<String> {
  LocaleProvider(this._settings, {List<String> deviceLanguages = const <String>[]})
      : _device = deviceLanguages,
        super(resolve(_settings.settings.localeCode, deviceLanguages)) {
    _settings.addListener(_recompute);
  }

  static const List<String> supported = VerseRepository.languages;
  static const List<String> rightToLeft = <String>['ar', 'he'];

  final SettingsProvider _settings;
  List<String> _device;

  /// The language code to use. Accepts codes like `pt_BR`, `zh-Hans` and the
  /// old Hebrew code `iw`.
  static String resolve(String? override, List<String> deviceLanguages) {
    final String? chosen = _normalise(override);
    if (chosen != null) {
      return chosen;
    }
    for (final String d in deviceLanguages) {
      final String? match = _normalise(d);
      if (match != null) {
        return match;
      }
    }
    return VerseRepository.fallbackLanguage;
  }

  static String? _normalise(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }
    final String base = code.split(RegExp('[-_]')).first.toLowerCase();
    final String mapped = base == 'iw' ? 'he' : base;
    return supported.contains(mapped) ? mapped : null;
  }

  static bool isRtl(String languageCode) => rightToLeft.contains(languageCode);

  bool get isRightToLeft => isRtl(value);

  /// Called when the phone's language list changes.
  void deviceLanguagesChanged(List<String> languages) {
    _device = languages;
    _recompute();
  }

  void _recompute() => value = resolve(_settings.settings.localeCode, _device);

  /// Sets the player's choice, or clears it with null to follow the phone.
  Future<bool> choose(String? languageCode) => _settings.update(
        (SettingsModel s) => languageCode == null ? s.copyWith(clearLocale: true) : s.copyWith(localeCode: languageCode),
      );

  @override
  void dispose() {
    _settings.removeListener(_recompute);
    super.dispose();
  }
}
