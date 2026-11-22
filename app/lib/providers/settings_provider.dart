import 'package:flutter/foundation.dart';

import '../core/errors/app_error.dart';
import '../core/models/settings_model.dart';
import '../core/ports/storage_port.dart';
import '../core/storage/settings_codec.dart';

class SettingsState {
  const SettingsState({this.settings = const SettingsModel(), this.loaded = false, this.saveFailed = false});

  final SettingsModel settings;

  /// False until the saved settings have been read (defaults are in use before).
  final bool loaded;

  /// True when the last save failed; the change still applies for this session.
  final bool saveFailed;

  SettingsState copyWith({SettingsModel? settings, bool? loaded, bool? saveFailed}) => SettingsState(
        settings: settings ?? this.settings,
        loaded: loaded ?? this.loaded,
        saveFailed: saveFailed ?? this.saveFailed,
      );

  @override
  bool operator ==(Object other) =>
      other is SettingsState && other.settings == settings && other.loaded == loaded && other.saveFailed == saveFailed;

  @override
  int get hashCode => Object.hash(settings, loaded, saveFailed);
}

/// All user settings. A change applies at once, then is saved; a failed save
/// raises [SettingsState.saveFailed] and the next change tries again.
class SettingsProvider extends ValueNotifier<SettingsState> {
  SettingsProvider(this._storage) : super(const SettingsState());

  final StoragePort _storage;
  Future<void> _chain = Future<void>.value();

  SettingsModel get settings => value.settings;

  Future<void> load() async {
    SettingsModel loaded = const SettingsModel();
    try {
      loaded = SettingsCodec.decode(await _storage.readString(SettingsCodec.key));
    } on StorageError {
      // Defaults are fine; they are saved on the first change.
    }
    value = value.copyWith(settings: loaded, loaded: true);
  }

  /// Applies [change] to the current settings and saves. Returns whether the save worked.
  Future<bool> update(SettingsModel Function(SettingsModel current) change) {
    value = value.copyWith(settings: change(value.settings));
    final Future<bool> result = _chain.then((_) => _save());
    _chain = result.then((_) {});
    return result;
  }

  Future<bool> _save() async {
    try {
      await _storage.writeString(SettingsCodec.key, SettingsCodec.encode(value.settings));
      if (value.saveFailed) {
        value = value.copyWith(saveFailed: false);
      }
      return true;
    } on StorageError {
      value = value.copyWith(saveFailed: true);
      return false;
    }
  }
}
