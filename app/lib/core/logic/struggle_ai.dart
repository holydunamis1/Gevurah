import '../models/exchange_outcome.dart';
import '../models/exchange_record.dart';
import '../models/move_def.dart';
import '../models/struggle_def.dart';
import 'seeded_rng.dart';

/// Picks each struggle's next move. One behaviour per trait, all deterministic:
/// the same struggle, history and seed always give the same move. The AI sees
/// only the history of the bout, never frame time.
abstract final class StruggleAi {
  /// The fastest a telegraph can become after any adjustment, in ms.
  static const int minTelegraphMs = 300;

  /// The next move for [def] after the exchanges in [history].
  static MoveDef nextMove(StruggleDef def, List<ExchangeRecord> history, SeededRng rng) {
    final StruggleTrait trait = _traitToUse(def, rng);
    return _forTrait(trait, def, history, rng);
  }

  /// Percent of counter damage the struggle takes this exchange (100 is normal).
  /// Shame holds its guard up while the player is swinging wildly.
  static int damageTakenPercent(StruggleDef def, List<ExchangeRecord> history) {
    if (!def.hasTrait(StruggleTrait.guardLow)) {
      return 100;
    }
    final int from = history.length > 4 ? history.length - 4 : 0;
    int whiffs = 0;
    for (int i = from; i < history.length; i++) {
      final ExchangeRecord r = history[i];
      if (r.counter != OpeningAction.none && r.outcome.damageDealt == 0) {
        whiffs++;
      }
    }
    return whiffs >= 2 ? 60 : 100;
  }

  static StruggleTrait _traitToUse(StruggleDef def, SeededRng rng) {
    if (def.hasTrait(StruggleTrait.blended)) {
      const List<StruggleTrait> blend = <StruggleTrait>[
        StruggleTrait.erratic,
        StruggleTrait.deceptive,
        StruggleTrait.draining,
        StruggleTrait.baiting,
      ];
      final List<StruggleTrait> usable = blend.where(def.hasTrait).toList();
      if (usable.isNotEmpty) {
        return usable[rng.nextInt(usable.length)];
      }
    }
    return def.traits.first;
  }

  static MoveDef _forTrait(StruggleTrait trait, StruggleDef def, List<ExchangeRecord> history, SeededRng rng) {
    final int index = history.length;
    final ExchangeRecord? last = history.isEmpty ? null : history.last;
    switch (trait) {
      case StruggleTrait.erratic:
        final MoveDef m = _any(def, rng);
        return _telegraph(m, (m.telegraphMs * (0.85 + 0.3 * rng.nextDouble())).round());
      case StruggleTrait.accumulating:
        return _preferKinds(def, rng, const <MoveKind>[MoveKind.ping], 0.8);
      case StruggleTrait.charged:
        final List<MoveDef> heavies = _ofKind(def, MoveKind.heavy);
        if (index % 3 == 2 && heavies.isNotEmpty) {
          return heavies[rng.nextInt(heavies.length)];
        }
        final List<MoveDef> light = def.moves.where((MoveDef m) => m.kind != MoveKind.heavy).toList();
        return light.isEmpty ? _any(def, rng) : light[rng.nextInt(light.length)];
      case StruggleTrait.impatient:
        final MoveDef m = _any(def, rng);
        return _telegraph(m, (m.telegraphMs * 0.9).round());
      case StruggleTrait.crowding:
        final List<MoveDef> a = _ofKind(def, index.isEven ? MoveKind.strike : MoveKind.flurry);
        return a.isEmpty ? _any(def, rng) : a[rng.nextInt(a.length)];
      case StruggleTrait.draining:
        return _preferKinds(def, rng, const <MoveKind>[MoveKind.drain], 0.8);
      case StruggleTrait.costly:
        return _any(def, rng);
      case StruggleTrait.mirroring:
        if (last == null) {
          return def.moves.first;
        }
        return def.moves[(last.response.index + last.counter.index) % def.moves.length];
      case StruggleTrait.deceptive:
        return _fakeOrReal(def, rng, 0.4);
      case StruggleTrait.baiting:
        final List<MoveDef> baits = _ofKind(def, MoveKind.bait);
        if (baits.isNotEmpty && rng.chance(0.35)) {
          return baits[rng.nextInt(baits.length)];
        }
        final List<MoveDef> rest = def.moves.where((MoveDef m) => m.kind != MoveKind.bait).toList();
        return rest.isEmpty ? _any(def, rng) : rest[rng.nextInt(rest.length)];
      case StruggleTrait.retreating:
        if (last != null && last.outcome.damageDealt > 0) {
          return MoveDef(
            id: '${def.id}_retreat',
            kind: MoveKind.fake,
            telegraphMs: def.moves.first.telegraphMs,
            damage: 0,
          );
        }
        return _any(def, rng);
      case StruggleTrait.returning:
        final MoveDef m = _any(def, rng);
        if (last != null && last.outcome.damageDealt > 0) {
          return m.copyWith(damage: m.damage + last.outcome.damageDealt ~/ 4);
        }
        return m;
      case StruggleTrait.countering:
        if (last != null && last.counter == OpeningAction.combo) {
          final List<MoveDef> heavies = _ofKind(def, MoveKind.heavy);
          if (heavies.isNotEmpty) {
            final MoveDef m = heavies[rng.nextInt(heavies.length)];
            return _telegraph(m, (m.telegraphMs * 0.85).round());
          }
        }
        return _any(def, rng);
      case StruggleTrait.guardLow:
      case StruggleTrait.resilient:
        return _any(def, rng);
      case StruggleTrait.blended:
        return _any(def, rng);
      case StruggleTrait.copying:
        if (last == null) {
          return def.moves.first;
        }
        return def.moves[last.offset.abs.round() % def.moves.length];
      case StruggleTrait.late:
        final MoveDef m = _any(def, rng);
        return rng.chance(0.25) ? _telegraph(m, m.telegraphMs + 250) : m;
      case StruggleTrait.decoys:
        return _fakeOrReal(def, rng, 0.5);
      case StruggleTrait.repeating:
        if (last != null && rng.chance(0.5)) {
          return last.move;
        }
        return _any(def, rng);
      case StruggleTrait.splitting:
        return index.isEven ? def.moves.first : def.moves.last;
      case StruggleTrait.escalating:
        final MoveDef m = _any(def, rng);
        final int bonus = index ~/ 4 > 6 ? 6 : index ~/ 4;
        return m.copyWith(damage: m.damage + bonus);
      case StruggleTrait.perfectionist:
        final MoveDef m = _any(def, rng);
        if (last != null && last.outcome.quality != Quality.perfect) {
          return m.copyWith(damage: (m.damage * 1.3).round());
        }
        return m;
      case StruggleTrait.swarming:
        final MoveDef m = _preferKinds(def, rng, const <MoveKind>[MoveKind.ping, MoveKind.flurry], 0.8);
        final int extra = index ~/ 6 > 3 ? 3 : index ~/ 6;
        return m.copyWith(hits: m.hits + extra);
      case StruggleTrait.grudging:
        final MoveDef m = _any(def, rng);
        final int from = history.length > 5 ? history.length - 5 : 0;
        int misses = 0;
        for (int i = from; i < history.length; i++) {
          if (history[i].outcome.quality == Quality.miss) {
            misses++;
          }
        }
        final int bonus = misses * 2 > 8 ? 8 : misses * 2;
        return m.copyWith(damage: m.damage + bonus);
      case StruggleTrait.chipping:
        return _preferKinds(def, rng, const <MoveKind>[MoveKind.ping], 0.7);
    }
  }

  static MoveDef _any(StruggleDef def, SeededRng rng) => def.moves[rng.nextInt(def.moves.length)];

  static List<MoveDef> _ofKind(StruggleDef def, MoveKind kind) =>
      def.moves.where((MoveDef m) => m.kind == kind).toList();

  static MoveDef _telegraph(MoveDef m, int ms) =>
      m.copyWith(telegraphMs: ms < minTelegraphMs ? minTelegraphMs : ms);

  static MoveDef _preferKinds(StruggleDef def, SeededRng rng, List<MoveKind> kinds, double p) {
    final List<MoveDef> preferred = def.moves.where((MoveDef m) => kinds.contains(m.kind)).toList();
    if (preferred.isNotEmpty && rng.chance(p)) {
      return preferred[rng.nextInt(preferred.length)];
    }
    return _any(def, rng);
  }

  static MoveDef _fakeOrReal(StruggleDef def, SeededRng rng, double fakeChance) {
    final List<MoveDef> fakes = _ofKind(def, MoveKind.fake);
    final List<MoveDef> real = def.moves.where((MoveDef m) => m.kind != MoveKind.fake).toList();
    if (fakes.isNotEmpty && (real.isEmpty || rng.chance(fakeChance))) {
      return fakes[rng.nextInt(fakes.length)];
    }
    return real.isEmpty ? _any(def, rng) : real[rng.nextInt(real.length)];
  }
}
