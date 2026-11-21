import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/errors/app_error.dart';
import 'package:gevurah/core/models/curated_verse.dart';
import 'package:gevurah/core/models/license_notice.dart';
import 'package:gevurah/core/models/struggle_def.dart';
import 'package:gevurah/core/models/verse.dart';
import 'package:gevurah/core/models/verse_card_def.dart';
import 'package:gevurah/core/models/verse_ref.dart';
import 'package:gevurah/core/verses/verse_number_map.dart';
import 'package:gevurah/core/verses/verse_repository.dart';

Future<String> fromDisk(String path) async => File(path).readAsStringSync();

void main() {
  final VerseRepository repo = VerseRepository(fromDisk);

  group('repository', () {
    test('every moment has verses in every language', () async {
      final List<CuratedVerse> curated = await repo.curated();
      for (final String lang in VerseRepository.languages) {
        for (final VerseMoment m in VerseMoment.values) {
          final int expected = curated.where((CuratedVerse c) => c.fits(m)).length;
          final List<Verse> got = await repo.byMoment(m, lang);
          expect(got.length, expected, reason: '$lang ${m.name}');
          expect(got.every((Verse v) => v.language == lang), true, reason: '$lang ${m.name}');
        }
      }
    });

    test('byRef returns the bundled text', () async {
      final Verse? v = await repo.byRef(VerseRef.parse('Philippians 4:13'), 'en');
      expect(v!.text, 'I can do all things through Christ who gives me strength.');
      expect(v.translationId, 'engbsb');
    });

    test('an unknown language or a missing verse falls back to English', () async {
      expect((await repo.byRef(VerseRef.parse('Philippians 4:13'), 'xx'))!.language, 'en');
      expect(await repo.byRef(VerseRef.parse('Genesis 1:1'), 'en'), isNull);
    });

    test('every struggle has an opponent verse and every card has its verse', () async {
      for (final StruggleDef s in StruggleCatalog.all) {
        expect(await repo.preBoutFor(s.id, 'en'), isNotNull, reason: s.id);
      }
      for (final VerseCardDef c in CardCatalog.all) {
        final Verse? v = await repo.cardVerse(c.id, 'en');
        expect(v, isNotNull, reason: c.id);
        expect(v!.ref, c.ref, reason: c.id);
      }
      expect(await repo.preBoutFor('nonsense', 'en'), isNull);
    });

    test('pick is deterministic, honours the seed and skips excluded ids', () async {
      final Verse? a = await repo.pick(VerseMoment.daily, 'en', seed: 11);
      final Verse? b = await repo.pick(VerseMoment.daily, 'en', seed: 11);
      expect(a, b);
      final Set<String> seen = <String>{
        for (int seed = 0; seed < 60; seed++) (await repo.pick(VerseMoment.daily, 'en', seed: seed))!.ref.key,
      };
      expect(seen.length, greaterThan(10));
      final List<CuratedVerse> daily = (await repo.curated()).where((CuratedVerse c) => c.fits(VerseMoment.daily)).toList();
      final Set<String> allButOne = daily.skip(1).map((CuratedVerse c) => c.id).toSet();
      final Verse? only = await repo.pick(VerseMoment.daily, 'en', seed: 5, exclude: allButOne);
      expect(only!.ref, daily.first.ref);
    });

    test('excluding everything still gives a verse', () async {
      final Set<String> all = (await repo.curated()).map((CuratedVerse c) => c.id).toSet();
      expect(await repo.pick(VerseMoment.win, 'en', seed: 1, exclude: all), isNotNull);
    });

    test('licence notices: one per language, and all distinct sources listed', () async {
      for (final String lang in VerseRepository.languages) {
        final LicenseNotice? n = await repo.noticeFor(lang);
        expect(n!.license, isNotEmpty, reason: lang);
      }
      final List<LicenseNotice> all = await repo.allNotices();
      expect(all.map((LicenseNotice n) => n.id).toSet().length, all.length);
      expect(all.length, greaterThanOrEqualTo(10));
    });

    test('missing bundled data is a StorageError, a missing language bundle falls back', () async {
      final VerseRepository broken = VerseRepository((String p) async => throw const FormatException('gone'));
      await expectLater(broken.curated(), throwsA(isA<StorageError>()));
      final VerseRepository partial = VerseRepository((String p) async {
        if (p.endsWith('/fr.json')) {
          throw const FormatException('gone');
        }
        return fromDisk(p);
      });
      expect((await partial.byRef(VerseRef.parse('Philippians 4:13'), 'fr'))!.language, 'en');
    });

    test('damaged English data is a StorageError', () async {
      final VerseRepository damaged = VerseRepository((String p) async {
        if (p.endsWith('/en.json')) {
          return '{"language":"en"}';
        }
        return fromDisk(p);
      });
      await expectLater(damaged.byRef(VerseRef.parse('Philippians 4:13'), 'en'), throwsA(isA<StorageError>()));
    });
  });

  group('verse number map', () {
    test('it matches the alignment the scripture tools computed', () {
      final Map<String, Object?> data = jsonDecode(File('../tools/scripture/alignment.json').readAsStringSync())! as Map<String, Object?>;
      final Map<String, Object?> shifts = data['shifts']! as Map<String, Object?>;
      for (final MapEntry<String, Object?> e in shifts.entries) {
        final Map<String, Object?> expected = e.value! as Map<String, Object?>;
        final Map<String, int> actual = VerseNumberMap.shifts[e.key] ?? <String, int>{};
        expect(actual.length, expected.length, reason: e.key);
        for (final MapEntry<String, Object?> c in expected.entries) {
          expect(actual[c.key], c.value, reason: '${e.key} ${c.key}');
        }
      }
    });

    test('toLocal and toEnglish are inverses', () {
      const VerseRef psalm = VerseRef(19, 18, 2);
      expect(VerseNumberMap.toLocal(psalm, 'fr'), const VerseRef(19, 18, 3));
      expect(VerseNumberMap.toLocal(psalm, 'en'), psalm);
      expect(VerseNumberMap.toLocal(const VerseRef(19, 51, 10), 'zh'), const VerseRef(19, 51, 12));
      expect(VerseNumberMap.toEnglish(const VerseRef(19, 18, 3), 'fr'), psalm);
      expect(VerseNumberMap.toEnglish(const VerseRef(19, 18, 1), 'fr'), const VerseRef(19, 18, 1));
      expect(VerseNumberMap.toLocal(const VerseRef(50, 4, 13), 'ar'), const VerseRef(50, 4, 13));
    });
  });
}
