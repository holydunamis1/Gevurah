import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/logic/fight_rules.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/player_state.dart';
import 'package:gevurah/core/models/struggle_def.dart';

const MoveDef strike = MoveDef(id: 's', kind: MoveKind.strike, telegraphMs: 700, damage: 10);

StruggleDef struggle(List<StruggleTrait> traits, {int weight = 100}) => StruggleDef(
      id: 'x',
      track: StruggleTrack.values.first,
      tier: 1,
      weight: weight,
      traits: traits,
      moves: const <MoveDef>[strike],
    );

ExchangeRecord rec({int dealt = 0, int taken = 0, int stamina = 0}) => ExchangeRecord(
      index: 0,
      round: 1,
      move: strike,
      response: Response.guard,
      offset: const BeatOffset(0),
      outcome: ExchangeOutcome(
        quality: Quality.good,
        damageTaken: taken,
        damageDealt: dealt,
        staminaChange: stamina,
        opening: false,
      ),
    );

FightState playQuiet(FightState s, StruggleDef d, int n) {
  FightState state = s;
  for (int i = 0; i < n; i++) {
    state = FightRules.apply(state, rec(), d);
  }
  return state;
}

void main() {
  final StruggleDef plain = struggle(<StruggleTrait>[StruggleTrait.erratic]);

  test('damage moves Weight, Resolve and Stamina', () {
    final FightState s = FightRules.apply(const FightState.initial(100), rec(dealt: 12, taken: 7, stamina: -10), plain);
    expect(s.weight, 88);
    expect(s.player.resolve, 93);
    expect(s.player.stamina, 90);
    expect(s.exchangeIndex, 1);
    expect(s.phase, FightPhase.telegraph);
  });

  test('stamina is clamped to the range', () {
    final FightState s = FightRules.apply(const FightState.initial(100), rec(stamina: 50), plain);
    expect(s.player.stamina, 100);
    final FightState t = FightRules.apply(s.copyWith(player: s.player.copyWith(stamina: 3)), rec(stamina: -20), plain);
    expect(t.player.stamina, 0);
  });

  test('knocking the struggle to zero ends the bout', () {
    final FightState s = FightRules.apply(const FightState.initial(20), rec(dealt: 25), plain);
    expect(s.end, FightEnd.struggleDefeated);
    expect(s.phase, FightPhase.finished);
    expect(s.weight, 0);
  });

  test('a finished bout ignores further exchanges', () {
    final FightState s = FightRules.apply(const FightState.initial(20), rec(dealt: 25), plain);
    expect(FightRules.apply(s, rec(taken: 50), plain), s);
  });

  test('a resilient struggle rises once with a share of its Weight', () {
    final StruggleDef d = struggle(<StruggleTrait>[StruggleTrait.resilient]);
    final FightState a = FightRules.apply(const FightState.initial(100), rec(dealt: 100), d);
    expect(a.isFinished, false);
    expect(a.weight, 30);
    expect(a.struggleRises, 1);
    final FightState b = FightRules.apply(a, rec(dealt: 40), d);
    expect(b.end, FightEnd.struggleDefeated);
  });

  test('resolve at zero starts the ten-count; Resolve shows zero', () {
    final FightState s = FightRules.apply(const FightState.initial(100), rec(taken: 120), plain);
    expect(s.phase, FightPhase.tenCount);
    expect(s.player.downs, 1);
    expect(s.player.resolve, 0);
  });

  test('rising restores Resolve by taps, capped, and resumes', () {
    final FightState down = FightRules.apply(const FightState.initial(100), rec(taken: 120), plain);
    expect(FightRules.rise(down, 0).player.resolve, 20);
    expect(FightRules.rise(down, 3).player.resolve, 38);
    expect(FightRules.rise(down, 50).player.resolve, 60);
    expect(FightRules.rise(down, 3).phase, FightPhase.telegraph);
  });

  test('rise does nothing outside a ten-count', () {
    const FightState s = FightState.initial(100);
    expect(FightRules.rise(s, 5), s);
  });

  test('the third down ends the bout', () {
    FightState s = const FightState.initial(1000);
    for (int i = 0; i < 3; i++) {
      s = FightRules.apply(s, rec(taken: 200), plain);
      if (i < 2) {
        expect(s.phase, FightPhase.tenCount);
        s = FightRules.rise(s, 2);
      }
    }
    expect(s.end, FightEnd.playerDown);
    expect(s.player.downs, 3);
  });

  test('a round ends in the corner, then the next round starts refilled', () {
    FightState s = playQuiet(const FightState.initial(100), plain, FightTuning.exchangesPerRound);
    expect(s.phase, FightPhase.corner);
    s = s.copyWith(player: s.player.copyWith(stamina: 10, resolve: 50, breathCharges: 0));
    final FightState n = FightRules.endCorner(s, plain);
    expect(n.round, 2);
    expect(n.phase, FightPhase.telegraph);
    expect(n.player.stamina, 70);
    expect(n.player.resolve, 65);
    expect(n.player.breathCharges, PlayerState.breathPerRound);
  });

  test('crowding halves the corner stamina refill', () {
    final StruggleDef d = struggle(<StruggleTrait>[StruggleTrait.crowding]);
    FightState s = playQuiet(const FightState.initial(100), d, FightTuning.exchangesPerRound);
    s = s.copyWith(player: s.player.copyWith(stamina: 10));
    expect(FightRules.endCorner(s, d).player.stamina, 40);
  });

  test('endCorner only works in the corner', () {
    const FightState s = FightState.initial(100);
    expect(FightRules.endCorner(s, plain), s);
  });

  test('round three ends with a decision', () {
    FightState s = const FightState.initial(100);
    for (int r = 1; r <= 3; r++) {
      s = playQuiet(s, plain, FightTuning.exchangesPerRound);
      if (r < 3) {
        s = FightRules.endCorner(s, plain);
      }
    }
    expect(s.isFinished, true);
    expect(s.end, FightEnd.decisionWon);
  });

  test('decision compares points and a tie goes to the player', () {
    const PlayerState full = PlayerState.initial();
    expect(FightRules.decision(100, 40, full.copyWith(resolve: 70)), FightEnd.decisionWon);
    expect(FightRules.decision(100, 90, full.copyWith(resolve: 60)), FightEnd.decisionLost);
    expect(FightRules.decision(100, 70, full.copyWith(resolve: 70)), FightEnd.decisionWon);
    expect(FightRules.decision(100, 100, full.copyWith(resolve: 80, downs: 1)), FightEnd.decisionLost);
  });

  test('breathe refills stamina once per charge', () {
    FightState s = const FightState.initial(100);
    s = s.copyWith(player: s.player.copyWith(stamina: 5));
    final FightState a = FightRules.breathe(s);
    expect(a.player.stamina, 100);
    expect(a.player.breathCharges, 0);
    expect(FightRules.breathe(a.copyWith(player: a.player.copyWith(stamina: 5))).player.stamina, 5);
  });
}
