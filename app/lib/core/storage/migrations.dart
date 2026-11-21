import '../errors/app_error.dart';
import '../models/model_utils.dart';
import '../models/progress.dart';

/// Turns saved JSON at version n into version n + 1.
typedef MigrationStep = Map<String, Object?> Function(Map<String, Object?> json);

/// Runs migrations from the stored version up to the current one.
class Migrator {
  const Migrator({required this.currentVersion, this.steps = const <int, MigrationStep>{}});

  /// The app's own schema, with no steps yet because version 1 is the first.
  static const Migrator standard = Migrator(currentVersion: Progress.currentSchemaVersion);

  final int currentVersion;

  /// Step for `n` converts version n to n + 1.
  final Map<int, MigrationStep> steps;

  /// Brings [json] up to [currentVersion]. Throws a [StorageError] for a
  /// version below 1, a missing step or a step that fails. A version above
  /// [currentVersion] is the caller's to treat as read-only, never migrated.
  Map<String, Object?> migrate(Map<String, Object?> json) {
    int version;
    try {
      version = readInt(json, 'schemaVersion');
    } on FormatException catch (e) {
      throw StorageError('Saved data has no readable version', cause: e);
    }
    if (version < 1) {
      throw StorageError('Saved data has an invalid version: $version');
    }
    if (version > currentVersion) {
      throw StorageError('Saved data is from a newer version: $version');
    }
    Map<String, Object?> data = json;
    while (version < currentVersion) {
      final MigrationStep? step = steps[version];
      if (step == null) {
        throw StorageError('No migration from version $version');
      }
      try {
        data = step(data);
      } on Object catch (e) {
        throw StorageError('Migration from version $version failed', cause: e);
      }
      version++;
      data = <String, Object?>{...data, 'schemaVersion': version};
    }
    return data;
  }
}
