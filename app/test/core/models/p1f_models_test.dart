import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/errors/app_error.dart';
import 'package:gevurah/core/models/achievement_def.dart';
import 'package:gevurah/core/models/curated_verse.dart';
import 'package:gevurah/core/models/daily_challenge.dart';
import 'package:gevurah/core/models/license_notice.dart';
import 'package:gevurah/core/models/loadout.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/core/models/settings_model.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/models/verse.dart';
import 'package:gevurah/core/models/verse_card_def.dart';
import 'package:gevurah/core/models/verse_ref.dart';

void main() {
  group('VerseRef', () {
    test('parses names and numeric keys to the same ref', () {
      final VerseRef a = VerseRef.parse('Philippians 4:13');
      expect(a, const VerseRef(50, 4, 13));
      expect(VerseRef.parse('50.4.13'), a);
      expect(a.key, '50.4.13');
      expect(a.toString(), 'Philippians 4:13');
      expect(a.bookName, 'Philippians');
    });

    test('handles numbered books and Psalms', () {
      expect(VerseRef.parse('1 Corinthians 10:13').book, 46);
      expect(VerseRef.parse('Psalms 23:1').book, 19);
      expect(VerseRef.parse('Revelation 21:4').book, 66);
      expect(VerseRef.parse('Genesis 1:1').book, 1);
    });

    test('there are 66 books', () {
      expect(canonBooks.length, 66);
      expect(canonBooks.toSet().length, 66);
    });

    test('rejects bad input', () {
      expect(() => VerseRef.parse('Nowhere 1:1'), throwsFormatException);
      expect(() => VerseRef.parse('John 0:1'), throwsFormatException);
      expect(() => VerseRef.parse('John 3'), throwsFormatException);
      expect(() => VerseRef.parse('67.1.1'), throwsFormatException);
    });

    test('json round trip and equality', () {
      const VerseRef r = VerseRef(43, 3, 16);
      expect(VerseRef.fromJson(r.toJson()), r);
      expect(r.hashCode, VerseRef.parse('John 3:16').hashCode);
    });
  });

  group('Verse, CuratedVerse, LicenseNotice', () {
    test('Verse round trips', () {
      const Verse v = Verse(ref: VerseRef(1, 1, 1), text: 'sample', language: 'en', translationId: 'bsb');
      expect(Verse.fromJson(v.toJson()), v);
    });

    test('CuratedVerse round trips and answers fits', () {
      const CuratedVerse c = CuratedVerse(
        id: 'cv1',
        ref: VerseRef(23, 41, 10),
        moments: <VerseMoment>[VerseMoment.preBout, VerseMoment.corner],
      );
      expect(CuratedVerse.fromJson(c.toJson()), c);
      expect(c.fits(VerseMoment.corner), isTrue);
      expect(c.fits(VerseMoment.loss), isFalse);
    });

    test('CuratedVerse rejects an unknown moment', () {
      final Map<String, Object?> json = const CuratedVerse(id: 'x', ref: VerseRef(1, 1, 1), moments: <VerseMoment>[]).toJson();
      json['moments'] = <Object?>['during_fight'];
      expect(() => CuratedVerse.fromJson(json), throwsFormatException);
    });

    test('LicenseNotice round trips', () {
      const LicenseNotice n = LicenseNotice(
        id: 'n1',
        sourceName: 'Source',
        license: 'Public domain',
        attribution: '',
        link: 'https://example.org',
      );
      expect(LicenseNotice.fromJson(n.toJson()), n);
    });
  });

  group('VerseCardDef', () {
    test('modifier follows the type and trades one thing for another', () {
      expect(CardType.strike.modifier.perfectStrikeDamagePercent, greaterThan(0));
      expect(CardType.strike.modifier.comboStaminaDelta, 2);
      expect(CardType.guard.modifier.perfectGuardStaminaReturn, greaterThan(0));
      expect(CardType.guard.modifier.goodGuardReductionDeltaPercent, lessThan(0));
      expect(CardType.insight.modifier.telegraphDeltaMs, 60);
      expect(CardType.insight.modifier.strikeWindowDeltaMs, -20);
      expect(CardType.steadiness.modifier.lowResolveDamageReducePercent, greaterThan(0));
      expect(CardType.steadiness.modifier.staminaRegenPercent, lessThan(0));
    });

    test('json round trip, starter flag and keys', () {
      const VerseCardDef c = VerseCardDef(id: 'fear', ref: VerseRef(23, 41, 10), type: CardType.guard, earnedByStruggleId: 'fear');
      expect(VerseCardDef.fromJson(c.toJson()), c);
      expect(c.isStarter, isFalse);
      expect(c.nameKey, 'card_fear');
      expect(c.effectKey, 'card_type_guard');
      expect(c.tradeoffKey, 'card_type_guard_tradeoff');
      const VerseCardDef s = VerseCardDef(id: 's', ref: VerseRef(1, 1, 1), type: CardType.strike);
      expect(VerseCardDef.fromJson(s.toJson()).isStarter, isTrue);
    });
  });

  group('Loadout', () {
    test('equips up to three distinct cards', () {
      Loadout l = const Loadout.empty();
      l = l.equip('a').equip('b').equip('b').equip('c').equip('d');
      expect(l.cardIds, <String>['a', 'b', 'c']);
      expect(l.isFull, isTrue);
      expect(l.isValid, isTrue);
    });

    test('unequip and invalid detection', () {
      final Loadout l = const Loadout(cardIds: <String>['a', 'b'], stance: Stance.bold).unequip('a');
      expect(l.cardIds, <String>['b']);
      expect(const Loadout(cardIds: <String>['a', 'a'], stance: Stance.steady).isValid, isFalse);
      expect(const Loadout(cardIds: <String>['a', 'b', 'c', 'd'], stance: Stance.steady).isValid, isFalse);
    });

    test('json round trip and equality', () {
      const Loadout l = Loadout(cardIds: <String>['a', 'b'], stance: Stance.patient);
      expect(Loadout.fromJson(l.toJson()), l);
      expect(l.copyWith(stance: Stance.bold) == l, isFalse);
      expect(l.hashCode, Loadout.fromJson(l.toJson()).hashCode);
    });
  });

  group('Progress', () {
    test('initial owns the starters and nothing else', () {
      final Progress p = Progress.initial(starterCardIds: <String>['s1', 's2']);
      expect(p.schemaVersion, Progress.currentSchemaVersion);
      expect(p.cardsEarned, <String>['s1', 's2']);
      expect(p.totalStars, 0);
      expect(p.ownsCard('s1'), isTrue);
      expect(p.ownsCard('x'), isFalse);
      expect(p.starsFor('fear'), 0);
    });

    test('json round trip with data', () {
      final Progress p = Progress.initial(starterCardIds: <String>['s1']).copyWith(
        bouts: <String, BoutRecord>{'fear': const BoutRecord(stars: 3, wins: 2), 'worry': const BoutRecord(stars: 1, wins: 1)},
        tiersCleared: <int>[1],
        cardsEarned: <String>['s1', 'fear'],
        dailyHistory: <DailyRecord>[const DailyRecord(dateKey: '2026-11-19', completed: true, stars: 2)],
        achievements: <String>['first_win'],
        loadout: const Loadout(cardIds: <String>['fear'], stance: Stance.bold),
      );
      final Progress back = Progress.fromJson(p.toJson());
      expect(back, p);
      expect(back.hashCode, p.hashCode);
      expect(back.totalStars, 4);
      expect(back.starsFor('fear'), 3);
    });

    test('rejects stars out of range and bad shapes', () {
      expect(() => BoutRecord.fromJson(<String, Object?>{'stars': 4, 'wins': 1}), throwsFormatException);
      final Map<String, Object?> json = Progress.initial(starterCardIds: <String>[]).toJson();
      json['bouts'] = <String, Object?>{'fear': 'oops'};
      expect(() => Progress.fromJson(json), throwsFormatException);
    });
  });

  group('SettingsModel', () {
    test('defaults', () {
      const SettingsModel s = SettingsModel();
      expect(s.themeChoice, ThemeChoice.system);
      expect(s.localeCode, isNull);
      expect(s.timingAssist, isFalse);
      expect(s.remindersOn, isFalse);
      expect(s.reminderMinuteOfDay, 1200);
    });

    test('json round trip including a null and a set locale', () {
      const SettingsModel a = SettingsModel();
      expect(SettingsModel.fromJson(a.toJson()), a);
      final SettingsModel b = a.copyWith(localeCode: 'ar', themeChoice: ThemeChoice.dark, remindersOn: true);
      expect(SettingsModel.fromJson(b.toJson()), b);
      expect(b.copyWith(clearLocale: true).localeCode, isNull);
    });

    test('rejects a reminder time outside the day', () {
      final Map<String, Object?> json = const SettingsModel().toJson();
      json['reminderMinuteOfDay'] = 1440;
      expect(() => SettingsModel.fromJson(json), throwsFormatException);
    });
  });

  group('DailyChallenge and AchievementDef', () {
    test('DailyChallenge round trips and checks the date key', () {
      const DailyChallenge d = DailyChallenge(dateKey: '2026-11-19', seed: 7, struggleId: 'fear');
      expect(DailyChallenge.fromJson(d.toJson()), d);
      final Map<String, Object?> bad = d.toJson();
      bad['dateKey'] = '19/11/2026';
      expect(() => DailyChallenge.fromJson(bad), throwsFormatException);
    });

    test('AchievementDef round trips and keys', () {
      const AchievementDef a = AchievementDef(id: 'flawless', ruleId: 'no_downs');
      expect(AchievementDef.fromJson(a.toJson()), a);
      expect(a.nameKey, 'achievement_flawless');
      expect(a.descriptionKey, 'achievement_flawless_desc');
    });
  });

  group('AppError', () {
    test('kinds map to the taxonomy', () {
      expect(const UserRecoverableError('x').recoverable, isTrue);
      expect(const UserRecoverableError('x').retriable, isFalse);
      expect(const ThirdPartyError('x').retriable, isTrue);
      expect(const StorageError('x').retriable, isTrue);
      expect(const StorageError('x').kind, ErrorKind.storageDegraded);
      expect(const FatalError('x').recoverable, isFalse);
      expect(const FatalError('x').retriable, isFalse);
    });

    test('can be switched over exhaustively and keeps its cause', () {
      const AppError e = StorageError('write failed', cause: 'disk');
      final String label = switch (e) {
        UserRecoverableError() => 'user',
        ThirdPartyError() => 'third',
        StorageError() => 'storage',
        FatalError() => 'fatal',
      };
      expect(label, 'storage');
      expect(e.cause, 'disk');
      expect(e.toString(), contains('write failed'));
    });
  });
}
