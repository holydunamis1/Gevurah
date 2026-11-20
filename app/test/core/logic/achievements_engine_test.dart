import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/logic/achievements_engine.dart';
import 'package:gevurah/core/logic/progression_rules.dart';
import 'package:gevurah/core/models/achievement_def.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/daily_challenge.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/player_state.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/core/models/struggle_def.dart';
import 'package:gevurah/core/models/verse_card_def.dart';

const MoveDef strike = MoveDef(id: 's', kind: MoveKind.strike, telegraphMs: 700, damage: 10);

ExchangeRecord rec(Quality q) => ExchangeRecord(
      index: 0,
      round: 1,
      move: strike,
      response: Response.guard,
      offset: const BeatOffset(0),
      outcome: ExchangeOutcome(quality: q, damageTaken: 0, damageDealt: 0, staminaChange: 0, opening: false),
    );

FightState won({int downs = 0}) => FightState(
      round: 2,
      startingWeight: 100,
      weight: 0,
      player: PlayerState(resolve: 60, stamina: 50, downs: downs, breathCharges: 0),
      exchangeIndex: 30,
      phase: FightPhase.finished,
      end: FightEnd.struggleDefeated,
    );

Progress fresh() => Progress.initial(starterCardIds: CardCatalog.starterIds);

Progress withWins(Iterable<StruggleDef> list, {int stars = 1}) {
  final Map<String, BoutRecord> bouts = <String, BoutRecord>{
    for (final StruggleDef s in list) s.id: BoutRecord(stars: stars, wins: 1),
  };
  final Progress p = fresh().copyWith(bouts: bouts);
  return p.copyWith(tiersCleared: ProgressionRules.tiersClearedFor(p));
}

void main() {
  test('every achievement has a unique id and a rule that can hold', () {
    final Set<String> ids = AchievementCatalog.all.map((AchievementDef a) => a.id).toSet();
    expect(ids.length, AchievementCatalog.all.length);
    expect(AchievementCatalog.byId('first_win')!.ruleId, 'first_win');
    expect(AchievementCatalog.byId('nope'), isNull);
  });

  test('a new player has nothing', () {
    expect(AchievementsEngine.evaluate(AchievementContext(progress: fresh())), isEmpty);
  });

  test('first win and no-downs after a clean win', () {
    final List<String> got = AchievementsEngine.evaluate(AchievementContext(
      progress: withWins(<StruggleDef>[StruggleCatalog.career.first]),
      finalState: won(),
    ));
    expect(got, <String>['first_win', 'no_downs']);
  });

  test('getting back up shows only when a win had downs', () {
    final List<String> got = AchievementsEngine.evaluate(AchievementContext(
      progress: withWins(<StruggleDef>[StruggleCatalog.career.first]),
      finalState: won(downs: 2),
    ));
    expect(got, contains('got_back_up'));
    expect(got, isNot(contains('no_downs')));
  });

  test('already unlocked achievements are not repeated', () {
    final Progress p = withWins(<StruggleDef>[StruggleCatalog.career.first]).copyWith(achievements: <String>['first_win']);
    expect(AchievementsEngine.evaluate(AchievementContext(progress: p)), isEmpty);
  });

  test('a perfect run needs five perfects in a row', () {
    final List<ExchangeRecord> broken = <ExchangeRecord>[
      rec(Quality.perfect), rec(Quality.perfect), rec(Quality.perfect), rec(Quality.perfect),
      rec(Quality.good),
      rec(Quality.perfect), rec(Quality.perfect),
    ];
    expect(AchievementsEngine.evaluate(AchievementContext(progress: fresh(), history: broken)), isEmpty);
    final List<ExchangeRecord> run = List<ExchangeRecord>.generate(5, (int i) => rec(Quality.perfect));
    expect(AchievementsEngine.evaluate(AchievementContext(progress: fresh(), history: run)), <String>['perfect_run']);
  });

  test('tiers, still standing, trials, cards, stars', () {
    final Progress all = withWins(<StruggleDef>[...StruggleCatalog.career, ...StruggleCatalog.trials], stars: 3).copyWith(
      cardsEarned: <String>[...CardCatalog.starterIds, ...CardCatalog.earned.map((VerseCardDef c) => c.id)],
    );
    final List<String> got = AchievementsEngine.evaluate(AchievementContext(progress: all));
    expect(got, containsAll(<String>[
      'first_win', 'three_stars', 'tier_1', 'tier_2', 'tier_3', 'tier_4',
      'still_standing', 'trials_done', 'ten_cards', 'twenty_stars',
    ]));
  });

  test('ten cards ignores the starters', () {
    final Progress p = fresh().copyWith(
      cardsEarned: <String>[...CardCatalog.starterIds, ...CardCatalog.earned.take(9).map((VerseCardDef c) => c.id)],
    );
    expect(AchievementsEngine.evaluate(AchievementContext(progress: p)), isNot(contains('ten_cards')));
  });

  test('daily streak achievements need the date', () {
    Progress p = fresh();
    for (final String k in <String>['2026-11-18', '2026-11-19', '2026-11-20']) {
      p = ProgressionRules.applyDaily(p, DailyChallenge(dateKey: k, seed: 1, struggleId: 'fear'), completed: true, stars: 1);
    }
    expect(AchievementsEngine.evaluate(AchievementContext(progress: p)), isEmpty);
    expect(AchievementsEngine.evaluate(AchievementContext(progress: p, todayKey: '2026-11-20')), <String>['daily_3']);
  });
}
