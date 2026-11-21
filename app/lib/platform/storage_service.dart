import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors/app_error.dart';
import '../core/ports/storage_port.dart';

/// Where small key-value strings live. Real code uses shared_preferences;
/// tests use memory.
abstract class KeyValueBackend {
  Future<String?> get(String key);

  Future<void> set(String key, String value);

  Future<void> remove(String key);
}

class SharedPrefsBackend implements KeyValueBackend {
  SharedPrefsBackend() : _prefs = SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> get(String key) => _prefs.getString(key);

  @override
  Future<void> set(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryBackend implements KeyValueBackend {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Real persistence. Files are written atomically (temporary file, then
/// rename). When a write fails the data is kept in memory, reads return it,
/// [degraded] turns true so the app can show a warning, and the next
/// successful write or [flushPending] clears it.
class StorageService implements StoragePort {
  StorageService({required Future<Directory> Function() directory, KeyValueBackend? backend})
      : _directory = directory,
        _backend = backend ?? SharedPrefsBackend();

  /// The app's private support folder and shared_preferences.
  factory StorageService.create() => StorageService(directory: getApplicationSupportDirectory);

  final Future<Directory> Function() _directory;
  final KeyValueBackend _backend;
  final Map<String, String> _pendingFiles = <String, String>{};
  final Map<String, String> _pendingStrings = <String, String>{};

  /// True while some data is held only in memory because a write failed.
  bool get degraded => _pendingFiles.isNotEmpty || _pendingStrings.isNotEmpty;

  static final RegExp _safeName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');

  String _checkName(String name) {
    if (!_safeName.hasMatch(name) || name.contains('..')) {
      throw StorageError('Not a valid file name: "$name"');
    }
    return name;
  }

  Future<File> _file(String name) async {
    final Directory dir = await _directory();
    return File('${dir.path}/${_checkName(name)}');
  }

  @override
  Future<String?> readFile(String name) async {
    _checkName(name);
    final String? pending = _pendingFiles[name];
    if (pending != null) {
      return pending;
    }
    try {
      final File f = await _file(name);
      return f.existsSync() ? await f.readAsString() : null;
    } on FileSystemException catch (e) {
      throw StorageError('Could not read "$name"', cause: e);
    }
  }

  @override
  Future<void> writeFile(String name, String contents) async {
    _checkName(name);
    try {
      final Directory dir = await _directory();
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final File target = File('${dir.path}/$name');
      final File temp = File('${dir.path}/$name.tmp');
      try {
        await temp.writeAsString(contents, flush: true);
        await temp.rename(target.path);
      } on FileSystemException {
        if (temp.existsSync()) {
          try {
            temp.deleteSync();
          } on FileSystemException {
            // Nothing more to do.
          }
        }
        rethrow;
      }
      _pendingFiles.remove(name);
    } on FileSystemException catch (e) {
      _pendingFiles[name] = contents;
      throw StorageError('Could not save "$name"; it is kept in memory for now', cause: e);
    }
  }

  @override
  Future<void> removeFile(String name) async {
    _checkName(name);
    _pendingFiles.remove(name);
    try {
      final File f = await _file(name);
      if (f.existsSync()) {
        await f.delete();
      }
    } on FileSystemException catch (e) {
      throw StorageError('Could not remove "$name"', cause: e);
    }
  }

  @override
  Future<String?> readString(String key) async {
    final String? pending = _pendingStrings[key];
    if (pending != null) {
      return pending;
    }
    try {
      return await _backend.get(key);
    } on Object catch (e) {
      throw StorageError('Could not read setting "$key"', cause: e);
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      await _backend.set(key, value);
      _pendingStrings.remove(key);
    } on Object catch (e) {
      _pendingStrings[key] = value;
      throw StorageError('Could not save setting "$key"; it is kept in memory for now', cause: e);
    }
  }

  @override
  Future<void> removeString(String key) async {
    _pendingStrings.remove(key);
    try {
      await _backend.remove(key);
    } on Object catch (e) {
      throw StorageError('Could not remove setting "$key"', cause: e);
    }
  }

  /// Tries again to write everything held in memory. Returns true when nothing
  /// is left pending.
  Future<bool> flushPending() async {
    for (final MapEntry<String, String> e in Map<String, String>.of(_pendingFiles).entries) {
      try {
        await writeFile(e.key, e.value);
      } on StorageError {
        // Stays pending.
      }
    }
    for (final MapEntry<String, String> e in Map<String, String>.of(_pendingStrings).entries) {
      try {
        await writeString(e.key, e.value);
      } on StorageError {
        // Stays pending.
      }
    }
    return !degraded;
  }
}
