import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/ports/haptics_port.dart';
import 'package:gevurah/core/ports/log_port.dart';
import 'package:gevurah/platform/audio_service.dart';
import 'package:gevurah/platform/connectivity_service.dart';
import 'package:gevurah/platform/haptics_service.dart';
import 'package:gevurah/platform/notification_service.dart';
import 'package:gevurah/platform/url_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../fakes/fakes.dart';

class RecordingDriver implements AudioDriver {
  final List<String> calls = <String>[];
  bool failing = false;

  void _maybeFail() {
    if (failing) {
      throw StateError('engine down');
    }
  }

  @override
  Future<void> load(List<String> paths) async {
    _maybeFail();
    calls.add('load ${paths.join(',')}');
  }

  @override
  Future<void> play(String path, double volume) async {
    _maybeFail();
    calls.add('play $path $volume');
  }

  @override
  Future<void> startLoop(String path, double volume) async {
    _maybeFail();
    calls.add('loop $path $volume');
  }

  @override
  Future<void> stopLoop() async {
    _maybeFail();
    calls.add('stop');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService', () {
    test('online when any network is present', () async {
      expect(await ConnectivityService(check: () async => <ConnectivityResult>[ConnectivityResult.wifi]).isOnline(), true);
      expect(await ConnectivityService(check: () async => <ConnectivityResult>[ConnectivityResult.none]).isOnline(), false);
      expect(await ConnectivityService(check: () async => <ConnectivityResult>[]).isOnline(), false);
    });

    test('a failing plugin does not block anything', () async {
      expect(await ConnectivityService(check: () async => throw StateError('x')).isOnline(), true);
    });

    test('changes are mapped and de-duplicated', () async {
      final StreamController<List<ConnectivityResult>> c = StreamController<List<ConnectivityResult>>();
      final ConnectivityService s = ConnectivityService(check: () async => <ConnectivityResult>[], changes: c.stream);
      final Future<List<bool>> got = s.onlineChanges.toList();
      c.add(<ConnectivityResult>[ConnectivityResult.mobile]);
      c.add(<ConnectivityResult>[ConnectivityResult.wifi]);
      c.add(<ConnectivityResult>[ConnectivityResult.none]);
      await c.close();
      expect(await got, <bool>[true, false]);
    });
  });

  group('HapticsService', () {
    final List<String> calls = <String>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add('${call.arguments}');
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('each kind sends its own pulse', () async {
      final HapticsService h = HapticsService();
      for (final HapticKind k in HapticKind.values) {
        await h.play(k);
      }
      expect(calls.length, HapticKind.values.length);
      expect(calls.toSet().length, HapticKind.values.length - 1 + 1, reason: 'error uses the plain vibrate type');
    });

    test('nothing plays when haptics are off', () async {
      final HapticsService h = HapticsService()..enabled = false;
      await h.play(HapticKind.hit);
      expect(calls, isEmpty);
    });
  });

  group('AudioService', () {
    test('ids become asset paths, volume is clamped', () async {
      final RecordingDriver d = RecordingDriver();
      final AudioService s = AudioService(driver: d);
      await s.preload(<String>['tap', 'hit']);
      await s.play('tap', volume: 3);
      await s.startLoop('menu');
      await s.stopLoop();
      expect(d.calls, <String>[
        'load assets/audio/tap.wav,assets/audio/hit.wav',
        'play assets/audio/tap.wav 1.0',
        'loop assets/audio/menu.wav 0.5',
        'stop',
      ]);
    });

    test('muting stops the loop and silences effects until unmuted', () async {
      final RecordingDriver d = RecordingDriver();
      final AudioService s = AudioService(driver: d);
      s.setMuted(true);
      await Future<void>.delayed(Duration.zero);
      await s.play('tap');
      await s.startLoop('menu');
      expect(d.calls, <String>['stop']);
      s.setMuted(false);
      await s.play('tap');
      expect(d.calls.last, 'play assets/audio/tap.wav 1.0');
    });

    test('a failing engine is logged, never thrown', () async {
      final RecordingDriver d = RecordingDriver()..failing = true;
      final FakeLog log = FakeLog();
      final AudioService s = AudioService(driver: d, log: log);
      await s.preload(<String>['tap']);
      await s.play('tap');
      await s.startLoop('menu');
      await s.stopLoop();
      expect(log.lines.length, 4);
      expect(log.lines.every((String l) => l.startsWith(LogLevel.warning.name)), true);
      await AudioService(driver: d).play('tap');
    });
  });

  group('UrlService', () {
    test('mail address encodes spaces and symbols without plus signs', () {
      final UrlService u = UrlService(supportEmail: 'help@example.com', launcher: (Uri x) async => true);
      expect(u.mailUri().toString(), 'mailto:help@example.com');
      final String s = u.mailUri(subject: 'Gevurah & me', body: 'a b\nc').toString();
      expect(s, 'mailto:help@example.com?subject=Gevurah%20%26%20me&body=a%20b%0Ac');
    });

    test('mail and https links open; other schemes and bad input do not', () async {
      final List<Uri> opened = <Uri>[];
      final UrlService u = UrlService(supportEmail: 'help@example.com', launcher: (Uri x) async {
        opened.add(x);
        return true;
      });
      expect(await u.openMail(subject: 'Hi'), true);
      expect(await u.openLink('https://example.com/licence'), true);
      expect(await u.openLink('http://example.com'), false);
      expect(await u.openLink('javascript:alert(1)'), false);
      expect(await u.openLink('https://'), false);
      expect(await u.openLink('not a url'), false);
      expect(opened.length, 2);
    });

    test('a failing launcher gives false', () async {
      final UrlService u = UrlService(supportEmail: 'a@b.c', launcher: (Uri x) async => throw StateError('no app'));
      expect(await u.openMail(), false);
      expect(await u.openLink('https://example.com'), false);
    });
  });

  group('NotificationService.nextOccurrence', () {
    setUpAll(tzdata.initializeTimeZones);

    test('later today when the time has not passed', () {
      final tz.Location london = tz.getLocation('Europe/London');
      final tz.TZDateTime now = tz.TZDateTime(london, 2026, 11, 21, 8, 30);
      expect(NotificationService.nextOccurrence(now, 9 * 60), tz.TZDateTime(london, 2026, 11, 21, 9));
    });

    test('tomorrow when the time has passed or is exactly now', () {
      final tz.Location london = tz.getLocation('Europe/London');
      final tz.TZDateTime now = tz.TZDateTime(london, 2026, 11, 21, 9);
      expect(NotificationService.nextOccurrence(now, 9 * 60), tz.TZDateTime(london, 2026, 11, 22, 9));
      expect(NotificationService.nextOccurrence(now, 8 * 60 + 15), tz.TZDateTime(london, 2026, 11, 22, 8, 15));
    });

    test('rolls over month and year ends and keeps the wall-clock time across a clock change', () {
      final tz.Location london = tz.getLocation('Europe/London');
      expect(
        NotificationService.nextOccurrence(tz.TZDateTime(london, 2026, 12, 31, 23, 0), 7 * 60),
        tz.TZDateTime(london, 2027, 1, 1, 7),
      );
      final tz.TZDateTime next = NotificationService.nextOccurrence(tz.TZDateTime(london, 2027, 3, 27, 20), 9 * 60);
      expect(next.hour, 9);
      expect(next.day, 28);
    });
  });
}
