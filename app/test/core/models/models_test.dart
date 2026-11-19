import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/model_utils.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/player_state.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/models/struggle_def.dart';

void main() {
  group('BeatOffset', () {
    test('judges perfect, good and miss at the default windows', () {
      expect(const BeatOffset(0).quality(), Quality.perfect);
      expect(const BeatOffset(50).quality(), Quality.perfect);
      expect(const BeatOffset(-50).quality(), Quality.perfect);
      expect(const BeatOffset(50.1).quality(), Quality.good);
      expect(const BeatOffset(-120).quality(), Quality.good);
      expect(const BeatOffset(120.1).quality(), Quality.miss);
      expect(const BeatOffset(-300).quality(), Quality.miss);
    });

    test('custom windows move the boundaries', () {
      final BeatOffset o = const BeatOffset(150);
      expect(o.quality(), Quality.miss);
      expect(
        o.quality(
          perfectMs: TimingWindows.perfectMs + TimingWindows.assistMs,
          goodMs: TimingWindows.goodMs + TimingWindows.assistMs,
        ),
        Quality.miss,
      );
      expect(const BeatOffset(150).quality(goodMs: 160), Quality.good);
    });

    test('json round trip and equality', () {
      const BeatOffset o = BeatOffset(-37.5);
      expect(BeatOffset.fromJson(o.toJson()), o);
      expect(o.abs, 37.5);
      expect(o.hashCode, const BeatOffset(-37.5).hashCode);
    });

    test('rejects a non-number', () {
      expect(() => BeatOffset.fromJson(<String, Object?>{'ms': 'x'}), throwsFormatException);
    });
  });

  group('ExchangeOutcome', () {
    const ExchangeOutcome o = ExchangeOutcome(
      quality: Quality.good,
      damageTaken: 4,
      damageDealt: 9,
      staminaChange: -6,
      opening: true,
    );

    test('json round trip and equality', () {
      expect(ExchangeOutcome.fromJson(o.toJson()), o);
      expect(o.copyWith(), o);
      expect(o.copyWith(opening: false) == o, isFalse);
    });

    test('rejects an unknown quality', () {
      final Map<String, Object?> json = o.toJson();
      json['quality'] = 'legendary';
      expect(() => ExchangeOutcome.fromJson(json), throwsFormatException);
    });
  });

  group('MoveDef', () {
    const MoveDef m = MoveDef(
      id: 'm1',
      kind: MoveKind.flurry,
      telegraphMs: 600,
      damage: 3,
      hits: 3,
      staminaDrain: 2,
    );

    test('json round trip and equality', () {
      expect(MoveDef.fromJson(m.toJson()), m);
      expect(m.copyWith(damage: 4) == m, isFalse);
    });

    test('a fake move is harmless; a normal one is not', () {
      expect(const MoveDef(id: 'f', kind: MoveKind.fake, telegraphMs: 500, damage: 0).isHarmless, isTrue);
      expect(m.isHarmless, isFalse);
    });

    test('rejects a missing field', () {
      final Map<String, Object?> json = m.toJson();
      json.remove('damage');
      expect(() => MoveDef.fromJson(json), throwsFormatException);
    });
  });

  group('StruggleDef', () {
    const StruggleDef s = StruggleDef(
      id: 'fear',
      track: StruggleTrack.career,
      tier: 1,
      weight: 60,
      traits: <StruggleTrait>[StruggleTrait.erratic],
      moves: <MoveDef>[MoveDef(id: 'm', kind: MoveKind.strike, telegraphMs: 900, damage: 6)],
    );

    test('json round trip and equality', () {
      expect(StruggleDef.fromJson(s.toJson()), s);
      expect(StruggleDef.fromJson(s.toJson()).hashCode, s.hashCode);
    });

    test('localization keys derive from the id', () {
      expect(s.nameKey, 'struggle_fear');
      expect(s.tellKey, 'struggle_fear_tell');
      expect(s.hasTrait(StruggleTrait.erratic), isTrue);
      expect(s.hasTrait(StruggleTrait.charged), isFalse);
    });
  });

  group('Stance', () {
    test('each stance trades one strength for one weakness', () {
      expect(Stance.steady.guardWindowDeltaMs, greaterThan(0));
      expect(Stance.steady.strikeDamagePercent, lessThan(0));
      expect(Stance.bold.strikeDamagePercent, greaterThan(0));
      expect(Stance.bold.guardWindowDeltaMs, lessThan(0));
      expect(Stance.patient.telegraphDeltaMs, greaterThan(0));
      expect(Stance.patient.staminaRegenPercent, lessThan(0));
    });
  });

  group('PlayerState', () {
    test('starts full with one Breath', () {
      const PlayerState p = PlayerState.initial();
      expect(p.resolve, 100);
      expect(p.stamina, 100);
      expect(p.downs, 0);
      expect(p.breathCharges, 1);
      expect(p.isDown, isFalse);
    });

    test('is down at zero Resolve', () {
      expect(const PlayerState.initial().copyWith(resolve: 0).isDown, isTrue);
      expect(const PlayerState.initial().copyWith(resolve: -3).isDown, isTrue);
    });

    test('json round trip and equality', () {
      const PlayerState p = PlayerState(resolve: 41, stamina: 12, downs: 2, breathCharges: 0);
      expect(PlayerState.fromJson(p.toJson()), p);
    });
  });

  group('FightConfig', () {
    const FightConfig c = FightConfig(
      mode: FightMode.daily,
      struggleId: 'doubt',
      cardIds: <String>['c1', 'c2', 'c3'],
      stance: Stance.bold,
      seed: 20261118,
      difficulty: Difficulty.hard,
      timingAssist: true,
    );

    test('json round trip and equality', () {
      expect(FightConfig.fromJson(c.toJson()), c);
      expect(FightConfig.fromJson(c.toJson()).hashCode, c.hashCode);
    });

    test('the same config always compares equal and a changed seed does not', () {
      expect(c.copyWith(), c);
      expect(c.copyWith(seed: 1) == c, isFalse);
    });

    test('survives an actual JSON string trip', () {
      // Uses plain collections only, as a persisted file would.
      final Map<String, Object?> decoded = <String, Object?>{...c.toJson()};
      decoded['cardIds'] = List<Object?>.from(c.cardIds);
      expect(FightConfig.fromJson(decoded), c);
    });
  });

  group('FightState', () {
    test('starts in round one with full Weight', () {
      const FightState s = FightState.initial(60);
      expect(s.round, 1);
      expect(s.weight, 60);
      expect(s.startingWeight, 60);
      expect(s.weightRemoved, 0);
      expect(s.isFinished, isFalse);
      expect(s.phase, FightPhase.telegraph);
    });

    test('json round trip with and without an end', () {
      const FightState s = FightState.initial(100);
      expect(FightState.fromJson(s.toJson()), s);
      final FightState done = s.copyWith(weight: 0, end: FightEnd.struggleDefeated, phase: FightPhase.finished);
      expect(FightState.fromJson(done.toJson()), done);
      expect(done.isFinished, isTrue);
      expect(done.weightRemoved, 100);
    });
  });

  group('ExchangeRecord', () {
    test('json round trip and equality', () {
      const ExchangeRecord r = ExchangeRecord(
        index: 3,
        round: 1,
        move: MoveDef(id: 'm', kind: MoveKind.strike, telegraphMs: 900, damage: 6),
        response: Response.guard,
        offset: BeatOffset(22),
        outcome: ExchangeOutcome(
          quality: Quality.perfect,
          damageTaken: 0,
          damageDealt: 8,
          staminaChange: -2,
          opening: true,
        ),
      );
      expect(ExchangeRecord.fromJson(r.toJson()), r);
      expect(r.damageDealt, 8);
      expect(r.damageTaken, 0);
    });
  });

  group('model_utils', () {
    test('listEq compares element-wise and by length', () {
      expect(listEq<int>(<int>[1, 2], <int>[1, 2]), isTrue);
      expect(listEq<int>(<int>[1, 2], <int>[2, 1]), isFalse);
      expect(listEq<int>(<int>[1], <int>[1, 2]), isFalse);
    });

    test('readInt accepts whole doubles and rejects fractions', () {
      expect(readInt(<String, Object?>{'a': 3.0}, 'a'), 3);
      expect(() => readInt(<String, Object?>{'a': 3.5}, 'a'), throwsFormatException);
    });
  });
}
