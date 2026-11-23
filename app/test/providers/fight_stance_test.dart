import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/storage/progress_store.dart';
import 'package:gevurah/providers/achievements_provider.dart';
import 'package:gevurah/providers/fight_provider.dart';
import 'package:gevurah/providers/progress_provider.dart';

import '../fakes/fakes.dart';

FightProvider newFight() {
  final ProgressProvider progress = ProgressProvider(ProgressStore(FakeStorage(), starterCardIds: CardCatalog.starterIds));
  final FightProvider f = FightProvider(progress: progress, achievements: AchievementsProvider(progress), clock: FakeClock(DateTime(2026, 11, 23)));
  f.start(FightConfig(
    mode: FightMode.training,
    struggleId: StruggleCatalog.career.first.id,
    cardIds: const <String>[],
    stance: Stance.steady,
    seed: 21,
  ));
  return f;
}

/// Plays to the first corner with perfect guards.
void toCorner(FightProvider f) {
  for (int i = 0; i < 600 && f.value!.state.phase != FightPhase.corner && !f.value!.finished; i++) {
    if (f.value!.state.phase == FightPhase.tenCount) {
      f.rise(3);
    } else {
      f.respond(response: Response.guard, offset: const BeatOffset(0));
    }
  }
}

void main() {
  test('the stance cannot change outside the corner', () {
    final FightProvider f = newFight();
    expect(f.changeStance(Stance.bold), isFalse);
    expect(f.value!.stanceChanges, isEmpty);
    expect(f.value!.stance, Stance.steady);
  });

  test('a corner change is recorded and takes effect for the next round', () {
    final FightProvider a = newFight();
    final FightProvider b = newFight();
    toCorner(a);
    toCorner(b);
    if (a.value!.state.phase != FightPhase.corner) {
      return;
    }
    expect(a.value!.state, b.value!.state);
    expect(a.changeStance(Stance.patient), isTrue);
    expect(a.value!.stance, Stance.patient);
    expect(a.value!.stanceChanges.length, 1);
    expect(a.value!.stanceChanges.single.exchangeIndex, a.value!.state.exchangeIndex);
    expect(a.changeStance(Stance.patient), isTrue);
    expect(a.value!.stanceChanges.length, 1);
    a.endCorner();
    b.endCorner();
    expect(a.value!.move!.kind, b.value!.move!.kind);
    expect(a.telegraphMs! - b.telegraphMs!, 120);
    expect(b.value!.stance, Stance.steady);
    expect(b.value!.stanceChanges, isEmpty);
  });

  test('the same changes at the same points give the same bout', () {
    List<ExchangeRecord> run() {
      final FightProvider f = newFight();
      toCorner(f);
      if (f.value!.state.phase == FightPhase.corner) {
        f.changeStance(Stance.bold);
        f.endCorner();
      }
      for (int i = 0; i < 600 && !f.value!.finished; i++) {
        final FightState s = f.value!.state;
        if (s.phase == FightPhase.corner) {
          f.endCorner();
        } else if (s.phase == FightPhase.tenCount) {
          f.rise(3);
        } else {
          f.respond(response: Response.guard, offset: const BeatOffset(0));
        }
      }
      return f.value!.history;
    }

    final List<ExchangeRecord> one = run();
    final List<ExchangeRecord> two = run();
    expect(one.length, two.length);
    for (int i = 0; i < one.length; i++) {
      expect(one[i].outcome, two[i].outcome);
    }
  });
}
