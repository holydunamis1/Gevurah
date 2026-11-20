import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/logic/daily_seed.dart';
import 'package:gevurah/core/logic/progression_rules.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/daily_challenge.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/player_state.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/models/struggle_def.dart';

const MoveDef strike = MoveDef(id: 's', kind: MoveKind.strike, telegraphMs: 700, damage: 10);

ExchangeRecord rec(Quality q) => ExchangeRecord(
      index: 0,
      round: 1,
      move: strike,
      response: Response.guard,
      offset: const BeatOffset(0),
      outcome: ExchangeOutcome(quality: q, damageTaken: 0, damageDealt: 0, staminaChange: 0, opening: false),
    );

FightState finished(FightEnd end, {int downs = 0, int resolve = 80}) => FightState(
      round: 3,
      startingWeight: 100,
      weight: end == FightEnd.struggleDefeated ? 0 : 40,
      player: PlayerState(resolve: resolve, stamina: 50, downs: downs, breathCharges: 0),
      exchangeIndex: 40,
      phase: FightPhase.finished,
      end: end,
    );

FightConfig config(String id, {FightMode mode = FightMode.journey}) =>
    FightConfig(mode: mode, struggleId: id, cardIds: const <String>[], stance: Stance.steady, seed: 1);

Progress fresh() => Progress.initial(starterCardIds: CardCatalog.starterIds);

Progress winAll(Progress p, Iterable<StruggleDef> list) {
  Progress out = p;
  for (final StruggleDef s in list) {
    out = ProgressionRules.applyResult(
      out,
      config(s.id, mode: s.track == StruggleTrack.career ? FightMode.journey : FightMode.trials),
      finished(FightEnd.struggleDefeated),
      <ExchangeRecord>[],
    );
  }
  return out;
}

void main() {
  group('stars', () {
    final List<ExchangeRecord> mostlyPerfect = <ExchangeRecord>[
      rec(Quality.perfect), rec(Quality.perfect), rec(Quality.good), rec(Quality.miss),
    ];
    final List<ExchangeRecord> few = <ExchangeRecord>[
      rec(Quality.perfect), rec(Quality.good), rec(Quality.good), rec(Quality.good), rec(Quality.miss),
    ];
    test('a loss earns none', () {
      expect(ProgressionRules.stars(finished(FightEnd.decisionLost), mostlyPerfect), 0);
      expect(ProgressionRules.stars(finished(FightEnd.playerDown, downs: 3), mostlyPerfect), 0);
    });
    test('a win with downs earns one', () {
      expect(ProgressionRules.stars(finished(FightEnd.struggleDefeated, downs: 1), mostlyPerfect), 1);
    });
    test('a win with no downs earns two, three with Resolve and perfects', () {
      expect(ProgressionRules.stars(finished(FightEnd.decisionWon), few), 2);
      expect(ProgressionRules.stars(finished(FightEnd.decisionWon, resolve: 30), mostlyPerfect), 2);
      expect(ProgressionRules.stars(finished(FightEnd.struggleDefeated), mostlyPerfect), 3);
    });
    test('an unfinished bout earns none and no history gives zero perfects', () {
      expect(ProgressionRules.stars(const FightState.initial(100), mostlyPerfect), 0);
      expect(ProgressionRules.perfectResponsePercent(<ExchangeRecord>[]), 0);
    });
  });

  group('unlocks', () {
    test('a new player has only the first struggle, daily and training', () {
      final Unlocks u = ProgressionRules.unlocksFor(fresh());
      expect(u.careerOpen, <String>[StruggleCatalog.career.first.id]);
      expect(u.trialsOpen, false);
      expect(u.sparringOpen, false);
      expect(u.enduranceOpen, false);
      expect(u.dailyOpen && u.trainingOpen, true);
    });

    test('career opens one struggle at a time', () {
      final Progress p = winAll(fresh(), StruggleCatalog.career.take(2));
      expect(ProgressionRules.unlocksFor(p).careerOpen.length, 3);
      expect(ProgressionRules.unlocksFor(p).sparringOpen, true);
    });

    test('tier 1 opens Trials, tier 2 opens Endurance', () {
      final Progress t1 = winAll(fresh(), StruggleCatalog.careerTier(1));
      expect(t1.tiersCleared, <int>[1]);
      expect(ProgressionRules.unlocksFor(t1).trialsOpen, true);
      expect(ProgressionRules.unlocksFor(t1).trialIdsOpen, <String>[StruggleCatalog.trials.first.id]);
      expect(ProgressionRules.unlocksFor(t1).enduranceOpen, false);
      final Progress t2 = winAll(t1, StruggleCatalog.careerTier(2));
      expect(t2.tiersCleared, <int>[1, 2]);
      expect(ProgressionRules.unlocksFor(t2).enduranceOpen, true);
    });

    test('canFight follows the unlocks', () {
      final Progress p = fresh();
      final String first = StruggleCatalog.career.first.id;
      final String second = StruggleCatalog.career[1].id;
      expect(ProgressionRules.canFight(p, FightMode.journey, first), true);
      expect(ProgressionRules.canFight(p, FightMode.journey, second), false);
      expect(ProgressionRules.canFight(p, FightMode.sparring, first), false);
      expect(ProgressionRules.canFight(p, FightMode.trials, StruggleCatalog.trials.first.id), false);
      expect(ProgressionRules.canFight(p, FightMode.endurance, first), false);
      expect(ProgressionRules.canFight(p, FightMode.training, second), true);
      expect(ProgressionRules.canFight(p, FightMode.daily, 'nonsense'), false);
      final Progress won = winAll(p, <StruggleDef>[StruggleCatalog.career.first]);
      expect(ProgressionRules.canFight(won, FightMode.sparring, first), true);
      expect(ProgressionRules.canFight(won, FightMode.journey, second), true);
    });
  });

  group('applyResult', () {
    test('a win records the bout and earns the card once', () {
      final String id = StruggleCatalog.career.first.id;
      final Progress p1 = ProgressionRules.applyResult(
        fresh(), config(id), finished(FightEnd.struggleDefeated), <ExchangeRecord>[rec(Quality.perfect)]);
      expect(p1.bouts[id]!.wins, 1);
      expect(p1.bouts[id]!.stars, 3);
      expect(p1.cardsEarned, contains(CardCatalog.earnedBy(id)!.id));
      final Progress p2 = ProgressionRules.applyResult(
        p1, config(id), finished(FightEnd.decisionWon, downs: 1), <ExchangeRecord>[]);
      expect(p2.bouts[id]!.wins, 2);
      expect(p2.bouts[id]!.stars, 3, reason: 'best stars are kept');
      expect(p2.cardsEarned.where((String c) => c == CardCatalog.earnedBy(id)!.id).length, 1);
    });

    test('a loss changes no wins and earns no card', () {
      final String id = StruggleCatalog.career.first.id;
      final Progress p = ProgressionRules.applyResult(
        fresh(), config(id), finished(FightEnd.decisionLost), <ExchangeRecord>[]);
      expect(p.bouts[id]!.wins, 0);
      expect(p.cardsEarned, CardCatalog.starterIds);
    });

    test('sparring records wins but earns no card; other modes change nothing', () {
      final String id = StruggleCatalog.career.first.id;
      final Progress won = winAll(fresh(), <StruggleDef>[StruggleCatalog.career.first]);
      final Progress s = ProgressionRules.applyResult(
        won, config(id, mode: FightMode.sparring), finished(FightEnd.struggleDefeated), <ExchangeRecord>[]);
      expect(s.bouts[id]!.wins, 2);
      expect(s.cardsEarned, won.cardsEarned);
      for (final FightMode m in <FightMode>[FightMode.daily, FightMode.endurance, FightMode.training]) {
        expect(
          ProgressionRules.applyResult(won, config(id, mode: m), finished(FightEnd.struggleDefeated), <ExchangeRecord>[]),
          won,
        );
      }
    });

    test('an unfinished bout changes nothing', () {
      final Progress p = fresh();
      expect(ProgressionRules.applyResult(p, config('fear'), const FightState.initial(100), <ExchangeRecord>[]), p);
    });
  });

  group('daily', () {
    const DailyChallenge d1 = DailyChallenge(dateKey: '2026-11-18', seed: 1, struggleId: 'fear');
    const DailyChallenge d2 = DailyChallenge(dateKey: '2026-11-19', seed: 2, struggleId: 'worry');
    const DailyChallenge d3 = DailyChallenge(dateKey: '2026-11-20', seed: 3, struggleId: 'anger');

    test('a completed day keeps its best stars and stays completed', () {
      Progress p = ProgressionRules.applyDaily(fresh(), d1, completed: true, stars: 2);
      p = ProgressionRules.applyDaily(p, d1, completed: false, stars: 0);
      p = ProgressionRules.applyDaily(p, d1, completed: true, stars: 1);
      expect(p.dailyHistory.length, 1);
      expect(p.dailyHistory.single.completed, true);
      expect(p.dailyHistory.single.stars, 2);
    });

    test('a failed first attempt is stored without stars', () {
      final Progress p = ProgressionRules.applyDaily(fresh(), d1, completed: false, stars: 3);
      expect(p.dailyHistory.single.completed, false);
      expect(p.dailyHistory.single.stars, 0);
    });

    test('streak counts consecutive completed days', () {
      Progress p = fresh();
      for (final DailyChallenge d in <DailyChallenge>[d3, d1, d2]) {
        p = ProgressionRules.applyDaily(p, d, completed: true, stars: 1);
      }
      expect(p.dailyHistory.map((DailyRecord r) => r.dateKey).toList(), <String>['2026-11-18', '2026-11-19', '2026-11-20']);
      expect(ProgressionRules.dailyStreak(p, '2026-11-20'), 3);
    });

    test('streak survives an unplayed today but not a missed day', () {
      Progress p = ProgressionRules.applyDaily(fresh(), d1, completed: true, stars: 1);
      p = ProgressionRules.applyDaily(p, d2, completed: true, stars: 1);
      expect(ProgressionRules.dailyStreak(p, '2026-11-20'), 2);
      expect(ProgressionRules.dailyStreak(p, '2026-11-21'), 0);
      expect(ProgressionRules.dailyStreak(p, 'bad'), 0);
    });

    test('streak crosses month and year ends', () {
      Progress p = fresh();
      for (final String k in <String>['2026-12-31', '2027-01-01']) {
        p = ProgressionRules.applyDaily(p, DailyChallenge(dateKey: k, seed: 1, struggleId: 'fear'), completed: true, stars: 1);
      }
      expect(ProgressionRules.dailyStreak(p, '2027-01-01'), 2);
    });
  });

  group('daily seed', () {
    test('the same date always gives the same challenge', () {
      expect(DailySeed.forDate(DateTime(2026, 11, 20)), DailySeed.forDate(DateTime(2026, 11, 20, 23, 59)));
    });

    test('the date key is zero padded', () {
      expect(DailySeed.dateKey(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('the seed is a fixed FNV hash, never the platform hash', () {
      expect(DailySeed.seedFor('2026-11-20'), DailySeed.seedFor('2026-11-20'));
      expect(DailySeed.seedFor('2026-11-20'), isNot(DailySeed.seedFor('2026-11-21')));
      expect(DailySeed.seedFor('2026-11-20'), inInclusiveRange(0, 0xFFFFFFFF));
    });

    test('the opponent is never the final bout, and many days vary', () {
      final Set<String> seen = <String>{};
      for (int d = 0; d < 365; d++) {
        final DailyChallenge c = DailySeed.forDate(DateTime(2026, 1, 1 + d));
        expect(StruggleCatalog.byId(c.struggleId)!.isFinal, false);
        seen.add(c.struggleId);
      }
      expect(seen.length, greaterThan(15));
    });
  });
}
