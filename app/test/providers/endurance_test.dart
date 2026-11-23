import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/logic/fight_rules.dart';
import 'package:gevurah/core/logic/struggle_ai.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/progress.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/storage/progress_store.dart';
import 'package:gevurah/providers/achievements_provider.dart';
import 'package:gevurah/providers/fight_provider.dart';
import 'package:gevurah/providers/progress_provider.dart';

import '../fakes/fakes.dart';

FightProvider make(FightMode mode, {ProgressProvider? progress}) {
  final ProgressProvider p = progress ?? ProgressProvider(ProgressStore(FakeStorage(), starterCardIds: CardCatalog.starterIds));
  final FightProvider f = FightProvider(progress: p, achievements: AchievementsProvider(p), clock: FakeClock(DateTime(2026, 11, 23)));
  f.start(FightConfig(mode: mode, struggleId: 'giving_up', cardIds: const <String>[], stance: Stance.steady, seed: 9));
  return f;
}

/// Plays until [n] exchanges are done (or the bout ends) with perfect guards.
void playTo(FightProvider f, int n) {
  while (f.value!.history.length < n && !f.value!.finished) {
    final FightState s = f.value!.state;
    if (s.phase == FightPhase.corner) {
      f.endCorner();
    } else if (s.phase == FightPhase.tenCount) {
      f.rise(3);
    } else {
      f.respond(response: Response.guard, offset: const BeatOffset(0));
    }
  }
}

/// Takes every hit until the run ends.
void loseRun(FightProvider f) {
  for (int i = 0; i < 2000 && !f.value!.finished; i++) {
    final FightState s = f.value!.state;
    if (s.phase == FightPhase.corner) {
      f.endCorner();
    } else if (s.phase == FightPhase.tenCount) {
      f.rise(0);
    } else {
      f.respond(response: Response.takeIt, offset: const BeatOffset(0));
    }
  }
}

void main() {
  test('an Endurance run has no last round, no decision and a struggle that does not run out', () {
    final FightProvider f = make(FightMode.endurance);
    playTo(f, FightTuning.exchangesPerRound * FightState.roundsPerBout + 12);
    final FightView v = f.value!;
    expect(v.finished, isFalse);
    expect(v.state.round, greaterThan(FightState.roundsPerBout));
    expect(v.state.weight, greaterThan(0));
  });

  test('a Journey bout with the same play still ends after round three', () {
    final FightProvider f = make(FightMode.journey);
    playTo(f, FightTuning.exchangesPerRound * FightState.roundsPerBout + 12);
    expect(f.value!.finished, isTrue);
  });

  test('the run ends on the last down', () {
    final FightProvider f = make(FightMode.endurance);
    loseRun(f);
    expect(f.value!.finished, isTrue);
    expect(f.value!.state.end, FightEnd.playerDown);
    expect(f.value!.state.player.downs, FightTuning.downsToEnd);
  });

  test('the pace rises: tells shorten every few exchanges, never below the floor', () {
    final FightProvider e = make(FightMode.endurance);
    final FightProvider j = make(FightMode.journey);
    playTo(e, 30);
    playTo(j, 30);
    final int endurance = e.value!.move!.telegraphMs;
    final int journey = j.value!.move!.telegraphMs;
    expect(e.value!.move!.kind, j.value!.move!.kind);
    expect(endurance, journey - 75 < StruggleAi.minTelegraphMs ? StruggleAi.minTelegraphMs : journey - 75);
    playTo(e, 200);
    expect(e.value!.move == null || e.value!.move!.telegraphMs >= StruggleAi.minTelegraphMs, isTrue);
  });

  test('the best run is kept and a shorter run does not replace it', () async {
    final ProgressProvider progress = ProgressProvider(ProgressStore(FakeStorage(), starterCardIds: CardCatalog.starterIds));
    await progress.load();
    final FightProvider first = make(FightMode.endurance, progress: progress);
    playTo(first, 40);
    loseRun(first);
    final int length = first.value!.history.length;
    final FightFinish? a = await first.finish();
    expect(progress.progress.enduranceBest, length);
    expect(a!.applied!.after.enduranceBest, length);
    expect(a.applied!.before.enduranceBest, 0);
    final FightProvider second = make(FightMode.endurance, progress: progress);
    loseRun(second);
    final FightFinish? b = await second.finish();
    expect(second.value!.history.length, lessThan(length));
    expect(progress.progress.enduranceBest, length);
    expect(b!.applied!.after.enduranceBest, b.applied!.before.enduranceBest);
  });

  test('an Endurance run records nothing in the career', () async {
    final ProgressProvider progress = ProgressProvider(ProgressStore(FakeStorage(), starterCardIds: CardCatalog.starterIds));
    await progress.load();
    final FightProvider f = make(FightMode.endurance, progress: progress);
    loseRun(f);
    await f.finish();
    expect(progress.progress.bouts, isEmpty);
  });

  test('enduranceBest saves and loads, and older saves read as zero', () {
    final Progress p = Progress.initial(starterCardIds: CardCatalog.starterIds).copyWith(enduranceBest: 37);
    expect(Progress.fromJson(p.toJson()).enduranceBest, 37);
    final Map<String, Object?> old = Map<String, Object?>.of(p.toJson())..remove('enduranceBest');
    expect(Progress.fromJson(old).enduranceBest, 0);
    expect(p == p.copyWith(enduranceBest: 38), isFalse);
  });
}
