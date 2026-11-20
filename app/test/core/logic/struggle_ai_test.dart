import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/logic/seeded_rng.dart';
import 'package:gevurah/core/logic/struggle_ai.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/struggle_def.dart';

ExchangeRecord rec(int i, MoveDef m, {int dealt = 0, int taken = 0, Quality q = Quality.good, OpeningAction c = OpeningAction.none}) {
  return ExchangeRecord(
    index: i,
    round: 1,
    move: m,
    response: Response.guard,
    offset: const BeatOffset(10),
    outcome: ExchangeOutcome(quality: q, damageTaken: taken, damageDealt: dealt, staminaChange: 0, opening: false),
    counter: c,
  );
}

void main() {
  test('every catalog struggle always yields a legal move', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      final SeededRng rng = SeededRng(7);
      final List<ExchangeRecord> history = <ExchangeRecord>[];
      for (int i = 0; i < 60; i++) {
        final MoveDef m = StruggleAi.nextMove(s, history, rng);
        expect(m.telegraphMs, greaterThanOrEqualTo(StruggleAi.minTelegraphMs), reason: s.id);
        expect(m.damage, greaterThanOrEqualTo(0), reason: s.id);
        expect(m.hits, greaterThanOrEqualTo(1), reason: s.id);
        history.add(rec(i, m, taken: i % 3 == 0 ? 5 : 0, q: i % 2 == 0 ? Quality.miss : Quality.good));
      }
    }
  });

  test('the same seed and history give the same moves', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      final List<String> a = <String>[];
      final List<String> b = <String>[];
      for (final List<String> out in <List<String>>[a, b]) {
        final SeededRng rng = SeededRng(99);
        final List<ExchangeRecord> h = <ExchangeRecord>[];
        for (int i = 0; i < 30; i++) {
          final MoveDef m = StruggleAi.nextMove(s, h, rng);
          out.add('${m.id}:${m.telegraphMs}:${m.damage}:${m.hits}');
          h.add(rec(i, m, taken: 3));
        }
      }
      expect(a, b, reason: s.id);
    }
  });

  const MoveDef strike = MoveDef(id: 's', kind: MoveKind.strike, telegraphMs: 700, damage: 10);
  const MoveDef heavy = MoveDef(id: 'h', kind: MoveKind.heavy, telegraphMs: 900, damage: 16);
  const MoveDef fake = MoveDef(id: 'k', kind: MoveKind.fake, telegraphMs: 700, damage: 0);

  StruggleDef def(StruggleTrait t, List<MoveDef> moves) => StruggleDef(
        id: 'x',
        track: StruggleTrack.values.first,
        tier: 1,
        weight: 100,
        traits: <StruggleTrait>[t],
        moves: moves,
      );

  test('charged throws a heavy on every third exchange', () {
    final StruggleDef d = def(StruggleTrait.charged, <MoveDef>[strike, heavy]);
    final SeededRng rng = SeededRng(1);
    final List<ExchangeRecord> h = <ExchangeRecord>[];
    for (int i = 0; i < 9; i++) {
      final MoveDef m = StruggleAi.nextMove(d, h, rng);
      expect(m.kind == MoveKind.heavy, i % 3 == 2, reason: 'exchange $i');
      h.add(rec(i, m));
    }
  });

  test('splitting alternates between first and last move', () {
    final StruggleDef d = def(StruggleTrait.splitting, <MoveDef>[strike, heavy]);
    final SeededRng rng = SeededRng(1);
    expect(StruggleAi.nextMove(d, <ExchangeRecord>[], rng).id, 's');
    expect(StruggleAi.nextMove(d, <ExchangeRecord>[rec(0, strike)], rng).id, 'h');
  });

  test('escalating adds damage over a bout, capped', () {
    final StruggleDef d = def(StruggleTrait.escalating, <MoveDef>[strike]);
    final SeededRng rng = SeededRng(1);
    final List<ExchangeRecord> h = List<ExchangeRecord>.generate(100, (int i) => rec(i, strike));
    expect(StruggleAi.nextMove(d, <ExchangeRecord>[], rng).damage, 10);
    expect(StruggleAi.nextMove(d, h, rng).damage, 16);
  });

  test('grudging punishes recent misses', () {
    final StruggleDef d = def(StruggleTrait.grudging, <MoveDef>[strike]);
    final SeededRng rng = SeededRng(1);
    final List<ExchangeRecord> h = List<ExchangeRecord>.generate(5, (int i) => rec(i, strike, q: Quality.miss));
    expect(StruggleAi.nextMove(d, h, rng).damage, 18);
  });

  test('perfectionist hits harder after the player is not perfect', () {
    final StruggleDef d = def(StruggleTrait.perfectionist, <MoveDef>[strike]);
    final SeededRng rng = SeededRng(1);
    expect(StruggleAi.nextMove(d, <ExchangeRecord>[rec(0, strike, q: Quality.perfect)], rng).damage, 10);
    expect(StruggleAi.nextMove(d, <ExchangeRecord>[rec(0, strike, q: Quality.good)], rng).damage, 13);
  });

  test('retreating answers a hit with a harmless fake', () {
    final StruggleDef d = def(StruggleTrait.retreating, <MoveDef>[strike]);
    final SeededRng rng = SeededRng(1);
    final MoveDef m = StruggleAi.nextMove(d, <ExchangeRecord>[rec(0, strike, dealt: 8)], rng);
    expect(m.kind, MoveKind.fake);
    expect(m.damage, 0);
  });

  test('decoys and deceptive use fakes when they have them', () {
    for (final StruggleTrait t in <StruggleTrait>[StruggleTrait.decoys, StruggleTrait.deceptive]) {
      final StruggleDef d = def(t, <MoveDef>[strike, fake]);
      final SeededRng rng = SeededRng(3);
      int fakes = 0;
      for (int i = 0; i < 100; i++) {
        if (StruggleAi.nextMove(d, <ExchangeRecord>[], rng).kind == MoveKind.fake) {
          fakes++;
        }
      }
      expect(fakes, inInclusiveRange(20, 80), reason: t.name);
    }
  });

  test('guardLow takes less damage after wild swings, others never change', () {
    final StruggleDef d = def(StruggleTrait.guardLow, <MoveDef>[strike]);
    final List<ExchangeRecord> whiffs = <ExchangeRecord>[
      rec(0, strike, c: OpeningAction.strike),
      rec(1, strike, c: OpeningAction.combo),
    ];
    expect(StruggleAi.damageTakenPercent(d, whiffs), 60);
    expect(StruggleAi.damageTakenPercent(d, <ExchangeRecord>[]), 100);
    expect(StruggleAi.damageTakenPercent(def(StruggleTrait.erratic, <MoveDef>[strike]), whiffs), 100);
  });
}
