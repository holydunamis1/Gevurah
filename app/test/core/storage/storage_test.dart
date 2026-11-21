import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/errors/app_error.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/core/models/settings_model.dart';
import 'package:gevurah/core/storage/migrations.dart';
import 'package:gevurah/core/storage/progress_codec.dart';
import 'package:gevurah/core/storage/progress_store.dart';
import 'package:gevurah/core/storage/settings_codec.dart';

import '../../fakes/fakes.dart';

Progress sample() => Progress.initial(starterCardIds: CardCatalog.starterIds).copyWith(
      bouts: const <String, BoutRecord>{'fear': BoutRecord(stars: 2, wins: 1)},
      tiersCleared: const <int>[1],
      dailyHistory: const <DailyRecord>[DailyRecord(dateKey: '2026-11-20', completed: true, stars: 3)],
      achievements: const <String>['first_win'],
    );

String sealed(String payload) => jsonEncode(<String, Object?>{
      'format': 1,
      'checksum': sha256.convert(utf8.encode(payload)).toString(),
      'payload': payload,
    });

void main() {
  group('Migrator', () {
    const Migrator one = Migrator.standard;

    test('current data passes through unchanged', () {
      final Map<String, Object?> json = sample().toJson();
      expect(one.migrate(json), json);
    });

    test('steps run in order and set the version', () {
      final List<int> order = <int>[];
      final Migrator m = Migrator(currentVersion: 3, steps: <int, MigrationStep>{
        1: (Map<String, Object?> j) {
          order.add(1);
          return <String, Object?>{...j, 'a': 1};
        },
        2: (Map<String, Object?> j) {
          order.add(2);
          return <String, Object?>{...j, 'b': 2};
        },
      });
      final Map<String, Object?> out = m.migrate(sample().toJson());
      expect(order, <int>[1, 2]);
      expect(out['schemaVersion'], 3);
      expect(out['a'], 1);
      expect(out['b'], 2);
    });

    test('a missing step, bad version or failing step is a StorageError', () {
      const Migrator two = Migrator(currentVersion: 2);
      expect(() => two.migrate(sample().toJson()), throwsA(isA<StorageError>()));
      expect(() => one.migrate(<String, Object?>{'schemaVersion': 0}), throwsA(isA<StorageError>()));
      expect(() => one.migrate(<String, Object?>{}), throwsA(isA<StorageError>()));
      expect(() => one.migrate(<String, Object?>{'schemaVersion': 5}), throwsA(isA<StorageError>()));
      final Migrator bad = Migrator(currentVersion: 2, steps: <int, MigrationStep>{
        1: (Map<String, Object?> j) => throw StateError('boom'),
      });
      expect(() => bad.migrate(sample().toJson()), throwsA(isA<StorageError>()));
    });
  });

  group('ProgressCodec', () {
    test('round trips', () {
      final ProgressDecoded d = ProgressCodec.decode(ProgressCodec.encode(sample()));
      expect(d.status, ProgressDecodeStatus.ok);
      expect(d.progress, sample());
      expect(d.storedVersion, Progress.currentSchemaVersion);
    });

    test('older data is migrated', () {
      final Migrator two = Migrator(currentVersion: 2, steps: <int, MigrationStep>{
        1: (Map<String, Object?> j) => j,
      });
      final ProgressDecoded d = ProgressCodec.decode(ProgressCodec.encode(sample()), migrator: two);
      expect(d.status, ProgressDecodeStatus.migrated);
      expect(d.progress!.bouts['fear']!.wins, 1);
    });

    test('a newer version is reported and not read', () {
      final String text = ProgressCodec.encode(sample().copyWith(schemaVersion: 7));
      final ProgressDecoded d = ProgressCodec.decode(text);
      expect(d.status, ProgressDecodeStatus.newerVersion);
      expect(d.progress, isNull);
      expect(d.storedVersion, 7);
    });

    test('every kind of damage is a StorageError', () {
      final String good = ProgressCodec.encode(sample());
      final Map<String, Object?> outer = jsonDecode(good)! as Map<String, Object?>;
      final List<String> bad = <String>[
        '',
        'not json',
        '[]',
        jsonEncode(<String, Object?>{...outer, 'format': 9}),
        jsonEncode(<String, Object?>{...outer, 'checksum': 'abc'}),
        jsonEncode(<String, Object?>{...outer, 'payload': '${outer['payload']} '}),
        jsonEncode(<String, Object?>{'format': 1}),
      ];
      for (final String text in bad) {
        expect(() => ProgressCodec.decode(text), throwsA(isA<StorageError>()), reason: text);
      }
    });

    test('a sealed payload that is not a save is a StorageError', () {
      final Map<String, Object?> missing = sample().toJson()..remove('bouts');
      for (final String payload in <String>['[]', 'nope', jsonEncode(missing), '{"schemaVersion":1}']) {
        expect(() => ProgressCodec.decode(sealed(payload)), throwsA(isA<StorageError>()), reason: payload);
      }
    });

    test('a sealed good payload decodes', () {
      expect(ProgressCodec.decode(sealed(jsonEncode(sample().toJson()))).progress, sample());
    });
  });

  group('ProgressStore', () {
    ProgressStore store(FakeStorage s) => ProgressStore(s, starterCardIds: CardCatalog.starterIds);

    test('nothing saved is a fresh start with the starter cards', () async {
      final ProgressLoad l = await store(FakeStorage()).load();
      expect(l.status, ProgressStoreStatus.fresh);
      expect(l.progress.cardsEarned, CardCatalog.starterIds);
      expect(l.canSave, true);
      expect(l.needsNotice, false);
    });

    test('save then load round trips', () async {
      final FakeStorage s = FakeStorage();
      final ProgressStore st = store(s);
      await st.load();
      expect(await st.save(sample()), true);
      final ProgressLoad l = await store(s).load();
      expect(l.status, ProgressStoreStatus.loaded);
      expect(l.progress, sample());
    });

    test('the previous good save becomes the backup', () async {
      final FakeStorage s = FakeStorage();
      final ProgressStore st = store(s);
      await st.load();
      await st.save(sample());
      final Progress second = sample().copyWith(achievements: const <String>['first_win', 'no_downs']);
      await st.save(second);
      expect(ProgressCodec.decode(s.files[ProgressStore.backupFile]!).progress, sample());
      expect(ProgressCodec.decode(s.files[ProgressStore.mainFile]!).progress, second);
    });

    test('a damaged main file recovers from the backup', () async {
      final FakeStorage s = FakeStorage();
      final ProgressStore st = store(s);
      await st.load();
      await st.save(sample());
      await st.save(sample());
      s.files[ProgressStore.mainFile] = 'garbage';
      final ProgressLoad l = await store(s).load();
      expect(l.status, ProgressStoreStatus.recoveredFromBackup);
      expect(l.progress, sample());
      expect(l.needsNotice, true);
    });

    test('a missing main file with a backup recovers too', () async {
      final FakeStorage s = FakeStorage();
      s.files[ProgressStore.backupFile] = ProgressCodec.encode(sample());
      expect((await store(s).load()).status, ProgressStoreStatus.recoveredFromBackup);
    });

    test('both files damaged starts clean with a notice and never throws', () async {
      final FakeStorage s = FakeStorage()
        ..files[ProgressStore.mainFile] = 'bad'
        ..files[ProgressStore.backupFile] = 'worse';
      final ProgressLoad l = await store(s).load();
      expect(l.status, ProgressStoreStatus.startedClean);
      expect(l.needsNotice, true);
      expect(l.canSave, true);
    });

    test('a damaged main file is not copied over a good backup', () async {
      final FakeStorage s = FakeStorage();
      final ProgressStore st = store(s);
      await st.load();
      await st.save(sample());
      s.files[ProgressStore.mainFile] = 'garbage';
      final String backupBefore = ProgressCodec.encode(sample());
      s.files[ProgressStore.backupFile] = backupBefore;
      await st.save(sample());
      expect(s.files[ProgressStore.backupFile], backupBefore);
    });

    test('a newer save is read-only and never overwritten', () async {
      final FakeStorage s = FakeStorage()
        ..files[ProgressStore.mainFile] = ProgressCodec.encode(sample().copyWith(schemaVersion: 9));
      final ProgressStore st = store(s);
      final ProgressLoad l = await st.load();
      expect(l.status, ProgressStoreStatus.readOnlyNewer);
      expect(l.canSave, false);
      final String before = s.files[ProgressStore.mainFile]!;
      expect(await st.save(sample()), false);
      expect(s.files[ProgressStore.mainFile], before);
      expect(s.writes, isEmpty);
    });

    test('an older save is migrated on load', () async {
      final FakeStorage s = FakeStorage()..files[ProgressStore.mainFile] = ProgressCodec.encode(sample());
      final ProgressStore st = ProgressStore(
        s,
        starterCardIds: CardCatalog.starterIds,
        migrator: Migrator(currentVersion: 2, steps: <int, MigrationStep>{1: (Map<String, Object?> j) => j}),
      );
      expect((await st.load()).status, ProgressStoreStatus.migrated);
    });

    test('unreadable storage gives a clean start instead of a crash', () async {
      final FakeStorage s = FakeStorage()..failReads = true;
      expect((await store(s).load()).status, ProgressStoreStatus.fresh);
    });

    test('a failed write is reported; a failed backup is not', () async {
      final FakeStorage s = FakeStorage();
      final ProgressStore st = store(s);
      await st.load();
      await st.save(sample());
      s.failWriteFor.add(ProgressStore.backupFile);
      expect(await st.save(sample()), true);
      s.failWrites = true;
      await expectLater(st.save(sample()), throwsA(isA<StorageError>()));
    });
  });

  group('SettingsCodec', () {
    test('round trips', () {
      const SettingsModel s = SettingsModel(themeChoice: ThemeChoice.dark, localeCode: 'ko', timingAssist: true, soundOn: false);
      expect(SettingsCodec.decode(SettingsCodec.encode(s)), s);
    });

    test('missing or damaged text gives the defaults', () {
      expect(SettingsCodec.decode(null), const SettingsModel());
      expect(SettingsCodec.decode('nope'), const SettingsModel());
      expect(SettingsCodec.decode('[]'), const SettingsModel());
      expect(SettingsCodec.decode('{"themeChoice":"pink"}'), const SettingsModel());
    });
  });

  group('fakes', () {
    test('FakeStorage keeps strings and files', () async {
      final FakeStorage s = FakeStorage();
      await s.writeString('k', 'v');
      expect(await s.readString('k'), 'v');
      await s.removeString('k');
      expect(await s.readString('k'), isNull);
      await s.writeFile('f', 'x');
      await s.removeFile('f');
      expect(await s.readFile('f'), isNull);
    });
  });
}
