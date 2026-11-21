/// Persistence the core needs, with no knowledge of how it is done. Every
/// method may throw a [StorageError]. Writes of files must be atomic: the
/// adapter writes a temporary file and renames it, so a crash never leaves a
/// half-written file.
abstract class StoragePort {
  /// A small key-value string (settings, flags). Null when absent.
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> removeString(String key);

  /// A whole file by name inside the app's private folder. Null when absent.
  Future<String?> readFile(String name);

  Future<void> writeFile(String name, String contents);

  Future<void> removeFile(String name);
}
