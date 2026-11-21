import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/errors/app_error.dart';
import 'package:gevurah/platform/storage_service.dart';

class FailingBackend implements KeyValueBackend {
  bool fail = true;
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> get(String key) async {
    if (fail) {
      throw StateError('down');
    }
    return values[key];
  }

  @override
  Future<void> set(String key, String value) async {
    if (fail) {
      throw StateError('down');
    }
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (fail) {
      throw StateError('down');
    }
    values.remove(key);
  }
}

void main() {
  late Directory dir;
  late StorageService service;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('gevurah_storage_');
    service = StorageService(directory: () async => dir, backend: MemoryBackend());
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('a missing file reads as null', () async {
    expect(await service.readFile('progress.json'), isNull);
  });

  test('write then read, overwrite and remove', () async {
    await service.writeFile('progress.json', 'one');
    expect(await service.readFile('progress.json'), 'one');
    await service.writeFile('progress.json', 'two');
    expect(await service.readFile('progress.json'), 'two');
    await service.removeFile('progress.json');
    expect(await service.readFile('progress.json'), isNull);
    await service.removeFile('progress.json');
  });

  test('writes are atomic: no temporary file is left behind', () async {
    await service.writeFile('progress.json', 'data');
    final List<String> names = dir.listSync().map((FileSystemEntity e) => e.path.split('/').last).toList();
    expect(names, <String>['progress.json']);
  });

  test('the folder is created when it does not exist yet', () async {
    final Directory nested = Directory('${dir.path}/a/b');
    final StorageService s = StorageService(directory: () async => nested, backend: MemoryBackend());
    await s.writeFile('x.json', 'y');
    expect(await s.readFile('x.json'), 'y');
  });

  test('unsafe names are refused', () async {
    for (final String name in <String>['', '../x', 'a/b', r'a\b', '.hidden', 'a..b']) {
      await expectLater(service.writeFile(name, 'x'), throwsA(isA<StorageError>()), reason: name);
      await expectLater(service.readFile(name), throwsA(isA<StorageError>()), reason: name);
    }
  });

  test('a failed write is kept in memory, reported, and flushed later', () async {
    final File blocker = File('${dir.path}/blocked')..writeAsStringSync('i am a file');
    Directory current = Directory(blocker.path);
    final StorageService s = StorageService(directory: () async => current, backend: MemoryBackend());
    await expectLater(s.writeFile('progress.json', 'kept'), throwsA(isA<StorageError>()));
    expect(s.degraded, true);
    expect(await s.readFile('progress.json'), 'kept');
    expect(await s.flushPending(), false);
    current = Directory('${dir.path}/ok');
    expect(await s.flushPending(), true);
    expect(s.degraded, false);
    expect(File('${dir.path}/ok/progress.json').readAsStringSync(), 'kept');
  });

  test('a later successful write clears the pending copy', () async {
    final File blocker = File('${dir.path}/blocked')..writeAsStringSync('x');
    Directory current = Directory(blocker.path);
    final StorageService s = StorageService(directory: () async => current, backend: MemoryBackend());
    await expectLater(s.writeFile('a.json', '1'), throwsA(isA<StorageError>()));
    current = Directory('${dir.path}/fine');
    await s.writeFile('a.json', '2');
    expect(s.degraded, false);
    expect(await s.readFile('a.json'), '2');
  });

  test('key-value strings round trip and remove', () async {
    await service.writeString('settings', '{}');
    expect(await service.readString('settings'), '{}');
    await service.removeString('settings');
    expect(await service.readString('settings'), isNull);
  });

  test('a failing key-value store falls back to memory and recovers', () async {
    final FailingBackend backend = FailingBackend();
    final StorageService s = StorageService(directory: () async => dir, backend: backend);
    await expectLater(s.writeString('k', 'v'), throwsA(isA<StorageError>()));
    expect(s.degraded, true);
    expect(await s.readString('k'), 'v');
    await expectLater(s.readString('other'), throwsA(isA<StorageError>()));
    await expectLater(s.removeString('other'), throwsA(isA<StorageError>()));
    backend.fail = false;
    expect(await s.flushPending(), true);
    expect(backend.values['k'], 'v');
    expect(s.degraded, false);
  });
}
