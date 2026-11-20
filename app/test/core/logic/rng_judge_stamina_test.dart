import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/logic/modifiers.dart';
import 'package:gevurah/core/logic/seeded_rng.dart';
import 'package:gevurah/core/logic/stamina.dart';
import 'package:gevurah/core/logic/timing_judge.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/stance.dart';

void main() {
  group('SeededRng', () {
    test('the same seed gives the same sequence', () {
      final SeededRng a = SeededRng(12345);
      final SeededRng b = SeededRng(12345);
      for (int i = 0; i < 200; i++) {
        expect(a.nextUint32(), b.nextUint32());
      }
    });

    test('different seeds differ', () {
      final List<int> a = <int>[for (int i = 0; i < 10; i++) SeededRng(1).nextUint32()];
      final SeededRng r = SeededRng(2);
      final List<int> b = <int>[for (int i = 0; i < 10; i++) r.nextUint32()];
      expect(a.first == b.first, isFalse);
    });

    test('has a known first value so a platform change would be caught', () {
      expect(SeededRng(0).nextUint32(), 1144304738);
      expect(SeededRng(1).nextUint32(), 2693262067);
    });

    test('nextInt stays in range and covers it', () {
      final SeededRng r = SeededRng(99);
      final Set<int> seen = <int>{};
      for (int i = 0; i < 500; i++) {
        final int v = r.nextInt(6);
        expect(v, inInclusiveRange(0, 5));
        seen.add(v);
      }
      expect(seen.length, 6);
      expect(() => r.nextInt(0), throwsArgumentError);
    });

    test('nextDouble is in [0, 1) and roughly uniform', () {
      final SeededRng r = SeededRng(7);
      double sum = 0;
      for (int i = 0; i < 4000; i++) {
        final double d = r.nextDouble();
        expect(d, greaterThanOrEqualTo(0));
        expect(d, lessThan(1));
        sum += d;
      }
      expect(sum / 4000, closeTo(0.5, 0.03));
    });

    test('chance respects its probability', () {
      final SeededRng r = SeededRng(5);
      int hits = 0;
      for (int i = 0; i < 4000; i++) {
        if (r.chance(0.25)) {
          hits++;
        }
      }
      expect(hits / 4000, closeTo(0.25, 0.04));
    });

    test('fork gives independent, repeatable streams', () {
      final SeededRng base1 = SeededRng(42);
      final SeededRng base2 = SeededRng(42);
      expect(base1.fork('ai').nextUint32(), base2.fork('ai').nextUint32());
      expect(SeededRng(42).fork('ai').nextUint32() == SeededRng(42).fork('fx').nextUint32(), isFalse);
    });
  });

  group('Modifiers', () {
    test('none changes nothing', () {
      expect(Modifiers.none.guardWindowDeltaMs, 0);
      expect(Modifiers.none.perfectStrikeDamagePercent, 0);
    });

    test('a stance alone adds its numbers', () {
      final Modifiers m = Modifiers.from(cardIds: const <String>[], stance: Stance.bold);
      expect(m.strikeDamagePercent, 20);
      expect(m.guardWindowDeltaMs, -15);
      expect(m.perfectStrikeDamagePercent, 0);
    });

    test('cards add their numbers and unknown ids are ignored', () {
      final Modifiers m = Modifiers.from(
        cardIds: const <String>['starter_strike', 'starter_insight', 'nonsense'],
        stance: Stance.steady,
      );
      expect(m.perfectStrikeDamagePercent, 25);
      expect(m.comboStaminaDelta, 2);
      expect(m.telegraphDeltaMs, 60);
      expect(m.strikeWindowDeltaMs, -20);
      expect(m.guardWindowDeltaMs, 15);
    });

    test('Patient adds telegraph and the Steadiness card adds a slower regen', () {
      final Modifiers m = Modifiers.from(cardIds: const <String>['starter_steadiness'], stance: Stance.patient);
      expect(m.telegraphDeltaMs, 120);
      expect(m.staminaRegenPercent, -45);
      expect(m.lowResolveDamageReducePercent, 25);
    });

    test('telegraphFor adds the delta and never goes under 200 ms', () {
      const MoveDef move = MoveDef(id: 'm', kind: MoveKind.strike, telegraphMs: 450, damage: 6);
      expect(const Modifiers(telegraphDeltaMs: 120).telegraphFor(move), 570);
      expect(const Modifiers(telegraphDeltaMs: -900).telegraphFor(move), 200);
    });

    test('equality', () {
      expect(const Modifiers(guardWindowDeltaMs: 5) == const Modifiers(guardWindowDeltaMs: 5), isTrue);
      expect(const Modifiers(guardWindowDeltaMs: 5) == const Modifiers(), isFalse);
      expect(const Modifiers().hashCode, const Modifiers().hashCode);
    });
  });

  group('TimingJudge', () {
    test('default windows', () {
      final Windows w = TimingJudge.responseWindows(Modifiers.none, isGuard: true);
      expect(w, const Windows(perfectMs: 50, goodMs: 120));
      expect(TimingJudge.judge(const BeatOffset(50), w), Quality.perfect);
      expect(TimingJudge.judge(const BeatOffset(-120), w), Quality.good);
      expect(TimingJudge.judge(const BeatOffset(121), w), Quality.miss);
    });

    test('assist widens each window by 40 ms', () {
      final Windows w = TimingJudge.responseWindows(Modifiers.none, isGuard: false, assist: true);
      expect(w, const Windows(perfectMs: 90, goodMs: 160));
    });

    test('the stance moves guard windows but not slip windows', () {
      const Modifiers steady = Modifiers(guardWindowDeltaMs: 15);
      expect(TimingJudge.responseWindows(steady, isGuard: true).goodMs, 135);
      expect(TimingJudge.responseWindows(steady, isGuard: false).goodMs, 120);
    });

    test('empty Stamina narrows guard windows by 30 percent', () {
      final Windows w = TimingJudge.responseWindows(Modifiers.none, isGuard: true, staminaEmpty: true);
      expect(w.perfectMs, closeTo(35, 0.001));
      expect(w.goodMs, closeTo(84, 0.001));
      expect(TimingJudge.responseWindows(Modifiers.none, isGuard: false, staminaEmpty: true).goodMs, 120);
    });

    test('the Insight card narrows strike windows', () {
      final Windows w = TimingJudge.strikeWindows(const Modifiers(strikeWindowDeltaMs: -20));
      expect(w, const Windows(perfectMs: 30, goodMs: 100));
    });

    test('a window never collapses below the minimum', () {
      final Windows w = TimingJudge.strikeWindows(const Modifiers(strikeWindowDeltaMs: -500));
      expect(w.perfectMs, TimingJudge.minWindowMs);
      expect(w.goodMs, greaterThanOrEqualTo(w.perfectMs));
    });
  });

  group('StaminaRules', () {
    test('costs', () {
      expect(StaminaRules.cost(StaminaAction.guard, Modifiers.none), 8);
      expect(StaminaRules.cost(StaminaAction.slip, Modifiers.none), 6);
      expect(StaminaRules.cost(StaminaAction.strike, Modifiers.none), 10);
      expect(StaminaRules.cost(StaminaAction.combo, Modifiers.none), 18);
    });

    test('the Strike card makes a Combo cost 2 more and Exhaustion doubles every cost', () {
      expect(StaminaRules.cost(StaminaAction.combo, const Modifiers(comboStaminaDelta: 2)), 20);
      expect(StaminaRules.cost(StaminaAction.guard, Modifiers.none, costly: true), 16);
      expect(StaminaRules.cost(StaminaAction.combo, const Modifiers(comboStaminaDelta: 2), costly: true), 40);
    });

    test('regeneration follows the modifiers and never goes negative', () {
      expect(StaminaRules.regen(Modifiers.none), 5);
      expect(StaminaRules.regen(const Modifiers(staminaRegenPercent: -25)), 4);
      expect(StaminaRules.regen(const Modifiers(staminaRegenPercent: -200)), 0);
    });

    test('clamp keeps values inside 0 to 100', () {
      expect(StaminaRules.clamp(-5), 0);
      expect(StaminaRules.clamp(50), 50);
      expect(StaminaRules.clamp(140), 100);
    });
  });
}
