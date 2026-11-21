import 'dart:convert';

import '../models/settings_model.dart';

/// Settings as one JSON string in the key-value store. Settings are never
/// worth a failure: anything unreadable gives the defaults.
abstract final class SettingsCodec {
  static const String key = 'settings';

  static String encode(SettingsModel settings) => jsonEncode(settings.toJson());

  static SettingsModel decode(String? text) {
    if (text == null) {
      return const SettingsModel();
    }
    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map<String, Object?>) {
        return SettingsModel.fromJson(decoded);
      }
    } on FormatException {
      // Fall through to the defaults.
    } on TypeError {
      // Fall through to the defaults.
    }
    return const SettingsModel();
  }
}
