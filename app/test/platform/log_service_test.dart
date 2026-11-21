import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/ports/log_port.dart';
import 'package:gevurah/platform/log_service.dart';

import '../fakes/fakes.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('gevurah_log_'));
  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('lines are written with time, level, message and error', () async {
    final LogService log = LogService(directory: () async => dir, clock: FakeClock(DateTime.utc(2026, 11, 21, 9)));
    log.log(LogLevel.info, 'started');
    log.log(LogLevel.error, 'failed', error: 'boom', stack: StackTrace.current);
    final String text = await log.exportText();
    expect(text, contains('2026-11-21T09:00:00.000Z INFO started'));
    expect(text, contains('ERROR failed | boom'));
    expect(text, startsWith('Gevurah Boxing log'));
  });

  test('the log rotates when the file grows', () async {
    final LogService log = LogService(directory: () async => dir, clock: FakeClock(DateTime.utc(2026)), maxBytes: 200);
    for (int i = 0; i < 20; i++) {
      log.log(LogLevel.info, 'line number $i with some padding text');
      await log.flush();
    }
    expect(File('${dir.path}/${LogService.previousName}').existsSync(), true);
    final String text = await log.exportText();
    expect(text, contains('line number 19'));
  });

  test('export is capped to the most recent text', () async {
    final LogService log = LogService(directory: () async => dir, clock: FakeClock(DateTime.utc(2026)), maxBytes: 1 << 20);
    for (int i = 0; i < 400; i++) {
      log.log(LogLevel.warning, 'x' * 100);
    }
    final String text = await log.exportText();
    expect(text.length, lessThanOrEqualTo(LogService.maxExportChars));
  });

  test('logging never throws, even when the folder cannot be used', () async {
    final File blocker = File('${dir.path}/blocked')..writeAsStringSync('x');
    final LogService log = LogService(directory: () async => Directory(blocker.path), clock: FakeClock(DateTime.utc(2026)));
    log.log(LogLevel.error, 'cannot be written');
    await log.flush();
    expect(await log.exportText(), contains('could not be read'));
  });
}
