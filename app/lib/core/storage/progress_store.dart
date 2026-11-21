import '../errors/app_error.dart';
import '../models/progress.dart';
import '../ports/storage_port.dart';
import 'migrations.dart';
import 'progress_codec.dart';

enum ProgressStoreStatus {
  /// Nothing saved yet.
  fresh,
  loaded,
  migrated,

  /// The main file was damaged or missing; the backup was used.
  recoveredFromBackup,

  /// Both files were unreadable; the player starts clean and sees a notice once.
  startedClean,

  /// Saved by a newer app. Read-only: never overwritten.
  readOnlyNewer,
}

class ProgressLoad {
  const ProgressLoad(this.progress, this.status);

  final Progress progress;
  final ProgressStoreStatus status;

  /// False when the save came from a newer app and must not be overwritten.
  bool get canSave => status != ProgressStoreStatus.readOnlyNewer;

  /// True when the player should see a one-time notice.
  bool get needsNotice =>
      status == ProgressStoreStatus.startedClean || status == ProgressStoreStatus.recoveredFromBackup;
}

/// Loads and saves progress with a backup copy and recovery.
class ProgressStore {
  ProgressStore(this._storage, {required this.starterCardIds, this.migrator = Migrator.standard});

  static const String mainFile = 'progress.json';
  static const String backupFile = 'progress.bak';

  final StoragePort _storage;
  final List<String> starterCardIds;
  final Migrator migrator;

  bool _readOnly = false;

  Progress _initial() => Progress.initial(starterCardIds: starterCardIds);

  Future<String?> _read(String name) async {
    try {
      return await _storage.readFile(name);
    } on StorageError {
      return null;
    }
  }

  ProgressDecoded? _tryDecode(String? text) {
    if (text == null) {
      return null;
    }
    try {
      return ProgressCodec.decode(text, migrator: migrator);
    } on StorageError {
      return null;
    }
  }

  ProgressLoad _from(ProgressDecoded d, {required bool fromBackup}) {
    if (d.status == ProgressDecodeStatus.newerVersion) {
      _readOnly = true;
      return ProgressLoad(_initial(), ProgressStoreStatus.readOnlyNewer);
    }
    final Progress p = d.progress!;
    if (fromBackup) {
      return ProgressLoad(p, ProgressStoreStatus.recoveredFromBackup);
    }
    return ProgressLoad(
      p,
      d.status == ProgressDecodeStatus.migrated ? ProgressStoreStatus.migrated : ProgressStoreStatus.loaded,
    );
  }

  /// Never throws: a damaged or missing save gives the backup or a clean start.
  Future<ProgressLoad> load() async {
    _readOnly = false;
    final String? mainText = await _read(mainFile);
    final ProgressDecoded? main = _tryDecode(mainText);
    if (main != null) {
      return _from(main, fromBackup: false);
    }
    final String? backupText = await _read(backupFile);
    final ProgressDecoded? backup = _tryDecode(backupText);
    if (backup != null) {
      return _from(backup, fromBackup: true);
    }
    if (mainText == null && backupText == null) {
      return ProgressLoad(_initial(), ProgressStoreStatus.fresh);
    }
    return ProgressLoad(_initial(), ProgressStoreStatus.startedClean);
  }

  /// Saves [progress]. Returns false, writing nothing, when the saved file is
  /// from a newer app. Throws a [StorageError] when the write fails.
  Future<bool> save(Progress progress) async {
    if (_readOnly) {
      return false;
    }
    final String? existing = await _read(mainFile);
    if (_tryDecode(existing) != null) {
      try {
        await _storage.writeFile(backupFile, existing!);
      } on StorageError {
        // A failed backup must not stop the save itself.
      }
    }
    await _storage.writeFile(mainFile, ProgressCodec.encode(progress));
    return true;
  }
}
