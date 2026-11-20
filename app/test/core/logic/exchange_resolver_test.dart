import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/logic/exchange_resolver.dart';
import 'package:gevurah/core/logic/modifiers.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/player_state.dart';

const MoveDef strike = MoveDef(id: 's', kind: MoveKind.strike, telegraphMs: 600, damage: 10);
const MoveDef heavy = MoveDef(id: 'h', kind: MoveKind.heavy, telegraphMs: 800, damage: 14);
const MoveDef flurry = MoveDef(id: 'f', kind: MoveKind.flurry, telegraphMs: 600, damage: 4, hits: 3);
const MoveDef ping = MoveDef(id: 'p', kind: MoveKind.ping, telegraphMs: 600, damage: 2, hits: 4);
const MoveDef fake = MoveDef(id: 'k', kind: MoveKind.fake, telegraphMs: 600, damage: 0);
const MoveDef bait = MoveDef(id: 'b', kind: MoveKind.bait, telegraphMs: 600, damage: 12);
const MoveDef drain = MoveDef(id: 'd', kind: MoveKind.drain, telegraphMs: 600, damage: 4, staminaDrain: 12);

ExchangeOutcome run(
  MoveDef move,
  Response response,
  double offset, {
  OpeningAction counter = OpeningAction.none,
  double? strikeOffset,
  ExchangeContext context = const ExchangeContext(),
}) {
  return ExchangeResolver.resolve(
    move: move,
    response: response,
    offset: BeatOffset(offset),
    counter: counter,
    strikeOffset: strikeOffset == null ? null : BeatOffset(strikeOffset),
    context: context,
  );
}

void main() {
  group('responses to a strike', () {
    test('a perfect guard takes nothing, returns Stamina and opens', () {
      final ExchangeOutcome o = run(strike, Response.guard, 0);
      expect(o.quality, Quality.perfect);
      expect(o.damageTaken, 0);
      expect(o.staminaChange, 1); // -8 cost, +4 perfect, +5 regen
      expect(o.opening, isTrue);
      expect(o.damageDealt, 0);
    });

    test('a good guard halves the damage and still opens', () {
      final ExchangeOutcome o = run(strike, Response.guard, 100);
      expect(o.quality, Quality.good);
      expect(o.damageTaken, 5);
      expect(o.staminaChange, -3);
      expect(o.opening, isTrue);
    });

    test('a missed guard takes everything and does not open', () {
      final ExchangeOutcome o = run(strike, Response.guard, 300);
      expect(o.quality, Quality.miss);
      expect(o.damageTaken, 10);
      expect(o.opening, isFalse);
      expect(o.staminaChange, -3);
    });

    test('taking it costs no Stamina, gains a little and opens nothing', () {
      final ExchangeOutcome o = run(strike, Response.takeIt, 0);
      expect(o.quality, Quality.miss);
      expect(o.damageTaken, 10);
      expect(o.staminaChange, 9); // +4 brace, +5 regen
      expect(o.opening, isFalse);
    });

    test('a perfect slip avoids a strike and costs less than a guard', () {
      final ExchangeOutcome o = run(strike, Response.slip, -20);
      expect(o.damageTaken, 0);
      expect(o.staminaChange, 3); // -6 cost, +4 perfect, +5 regen
    });
  });

  group('move kinds change what works', () {
    test('a guard beats a flurry better than a slip does', () {
      expect(run(flurry, Response.guard, 0).damageTaken, 0);
      expect(run(flurry, Response.slip, 0).damageTaken, 6);
      expect(run(flurry, Response.slip, 100).damageTaken, 9);
    });

    test('a heavy swing breaks a guard but not a slip', () {
      expect(run(heavy, Response.guard, 0).damageTaken, 4); // 25 percent of 14, rounded
      expect(run(heavy, Response.guard, 100).damageTaken, 9); // 65 percent of 14
      expect(run(heavy, Response.slip, 0).damageTaken, 0);
      expect(run(heavy, Response.slip, 100).damageTaken, 7);
    });

    test('many small hits add up when answered badly', () {
      expect(run(ping, Response.takeIt, 0).damageTaken, 8);
      expect(run(ping, Response.guard, 100).damageTaken, 4);
    });

    test('a drain move takes Stamina, softened by a good guard', () {
      final ExchangeOutcome o = run(drain, Response.guard, 100);
      expect(o.damageTaken, 2);
      expect(o.staminaChange, -9); // -8 guard, -6 drain, +5 regen
      expect(run(drain, Response.takeIt, 0).staminaChange, -3); // +4 brace, -12 drain, +5 regen
    });
  });

  group('fakes and baits', () {
    test('answering a fake costs Stamina and earns nothing', () {
      final ExchangeOutcome o = run(fake, Response.guard, 0);
      expect(o.damageTaken, 0);
      expect(o.opening, isFalse);
      expect(o.staminaChange, -3);
    });

    test('reading a fake and not reacting earns an opening', () {
      final ExchangeOutcome o = run(fake, Response.takeIt, 0);
      expect(o.damageTaken, 0);
      expect(o.opening, isTrue);
      expect(o.quality, Quality.good);
    });

    test('a bait answered well opens but is harmless if the player does not strike', () {
      final ExchangeOutcome o = run(bait, Response.guard, 0);
      expect(o.damageTaken, 0);
      expect(o.opening, isTrue);
    });

    test('striking into a bait is the trap', () {
      final ExchangeOutcome o = run(bait, Response.guard, 0, counter: OpeningAction.strike, strikeOffset: 0);
      expect(o.damageTaken, 12);
      expect(o.damageDealt, 0);
      expect(o.staminaChange, -9); // -8, +4, +5, -10
    });

    test('a missed bait is just a hit', () {
      final ExchangeOutcome o = run(bait, Response.guard, 300);
      expect(o.damageTaken, 12);
      expect(o.opening, isFalse);
    });
  });

  group('counters', () {
    test('a perfect strike after a perfect guard', () {
      final ExchangeOutcome o = run(strike, Response.guard, 0, counter: OpeningAction.strike, strikeOffset: 0);
      expect(o.damageDealt, 10); // 8 * 1.25
      expect(o.staminaChange, -9);
    });

    test('a good strike and a missed strike', () {
      expect(run(strike, Response.guard, 0, counter: OpeningAction.strike, strikeOffset: 100).damageDealt, 8);
      final ExchangeOutcome whiff = run(strike, Response.guard, 0, counter: OpeningAction.strike, strikeOffset: 300);
      expect(whiff.damageDealt, 0);
      expect(whiff.staminaChange, -9, reason: 'the swing still costs Stamina');
    });

    test('with no strike timing the response quality is used', () {
      expect(run(strike, Response.guard, 0, counter: OpeningAction.strike).damageDealt, 10);
    });

    test('a good response gives a shorter opening than a perfect one', () {
      final ExchangeOutcome o = run(strike, Response.guard, 100, counter: OpeningAction.strike, strikeOffset: 0);
      expect(o.damageDealt, 7); // 8 * 0.7 * 1.25
    });

    test('a combo hits harder and costs more', () {
      final ExchangeOutcome o = run(strike, Response.guard, 0, counter: OpeningAction.combo, strikeOffset: 0);
      expect(o.damageDealt, 18); // 14 * 1.25 = 17.5
      expect(o.staminaChange, -17);
    });

    test('no counter without an opening', () {
      final ExchangeOutcome o = run(strike, Response.guard, 300, counter: OpeningAction.strike, strikeOffset: 0);
      expect(o.damageDealt, 0);
      expect(o.staminaChange, -3);
    });

    test('a counter needs the Stamina for it', () {
      final ExchangeOutcome o = run(
        strike,
        Response.guard,
        0,
        counter: OpeningAction.strike,
        strikeOffset: 0,
        context: const ExchangeContext(player: PlayerState(resolve: 100, stamina: 5, downs: 0, breathCharges: 1)),
      );
      expect(o.damageDealt, 0);
      expect(o.staminaChange, 4); // guard capped at 5, +4 perfect, +5 regen, no strike cost
    });
  });

  group('modifiers and context', () {
    test('Bold makes strikes hit harder', () {
      final ExchangeOutcome o = run(
        strike,
        Response.guard,
        0,
        counter: OpeningAction.strike,
        strikeOffset: 0,
        context: const ExchangeContext(modifiers: Modifiers(strikeDamagePercent: 20)),
      );
      expect(o.damageDealt, 12);
    });

    test('the Strike card adds to perfect strikes only', () {
      const ExchangeContext c = ExchangeContext(modifiers: Modifiers(perfectStrikeDamagePercent: 25));
      expect(run(strike, Response.guard, 0, counter: OpeningAction.strike, strikeOffset: 0, context: c).damageDealt, 12);
      expect(run(strike, Response.guard, 0, counter: OpeningAction.strike, strikeOffset: 100, context: c).damageDealt, 8);
    });

    test('the Guard card makes a good guard block less', () {
      const ExchangeContext c = ExchangeContext(modifiers: Modifiers(goodGuardReductionDeltaPercent: -10));
      expect(run(strike, Response.guard, 100, context: c).damageTaken, 6);
    });

    test('the Guard card returns Stamina on a perfect guard', () {
      const ExchangeContext c = ExchangeContext(modifiers: Modifiers(perfectGuardStaminaReturn: 6));
      expect(run(strike, Response.guard, 0, context: c).staminaChange, 7);
    });

    test('the Steadiness card helps only at low Resolve', () {
      const Modifiers m = Modifiers(lowResolveDamageReducePercent: 25);
      const PlayerState low = PlayerState(resolve: 20, stamina: 100, downs: 0, breathCharges: 1);
      const PlayerState high = PlayerState(resolve: 50, stamina: 100, downs: 0, breathCharges: 1);
      expect(run(bait, Response.guard, 300, context: const ExchangeContext(modifiers: m, player: low)).damageTaken, 9);
      expect(run(bait, Response.guard, 300, context: const ExchangeContext(modifiers: m, player: high)).damageTaken, 12);
    });

    test('Timing assist turns a good response into a perfect one', () {
      expect(run(strike, Response.slip, 80).quality, Quality.good);
      expect(run(strike, Response.slip, 80, context: const ExchangeContext(assist: true)).quality, Quality.perfect);
    });

    test('empty Stamina narrows guard windows', () {
      const PlayerState empty = PlayerState(resolve: 100, stamina: 0, downs: 0, breathCharges: 1);
      final ExchangeOutcome o = run(strike, Response.guard, 40, context: const ExchangeContext(player: empty));
      expect(o.quality, Quality.good);
      expect(run(strike, Response.guard, 40).quality, Quality.perfect);
    });

    test('Exhaustion doubles what actions cost', () {
      final ExchangeOutcome o = run(strike, Response.guard, 0, context: const ExchangeContext(costly: true));
      expect(o.staminaChange, -7); // -16, +4, +5
    });

    test('Shame takes more counter damage when its guard is low', () {
      final ExchangeOutcome o = run(
        strike,
        Response.guard,
        0,
        counter: OpeningAction.strike,
        strikeOffset: 0,
        context: const ExchangeContext(struggleDamageTakenPercent: 150),
      );
      expect(o.damageDealt, 15);
    });
  });

  group('determinism', () {
    test('the same inputs always give the same outcome', () {
      for (int i = 0; i < 50; i++) {
        final double off = (i * 7.3) - 160;
        final ExchangeOutcome a = run(flurry, Response.guard, off, counter: OpeningAction.combo, strikeOffset: off / 2);
        final ExchangeOutcome b = run(flurry, Response.guard, off, counter: OpeningAction.combo, strikeOffset: off / 2);
        expect(a, b);
      }
    });

    test('damage is never negative and Stamina change is bounded', () {
      for (final MoveDef m in <MoveDef>[strike, heavy, flurry, ping, fake, bait, drain]) {
        for (final Response r in Response.values) {
          for (double off = -300; off <= 300; off += 25) {
            final ExchangeOutcome o = run(m, r, off, counter: OpeningAction.combo, strikeOffset: off);
            expect(o.damageTaken, greaterThanOrEqualTo(0));
            expect(o.damageDealt, greaterThanOrEqualTo(0));
            expect(o.staminaChange, inInclusiveRange(-60, 30));
          }
        }
      }
    });
  });
}
