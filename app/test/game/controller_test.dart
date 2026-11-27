import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/input/input_strategy.dart';
import 'package:gevurah/core/input/tap_swipe_strategy.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/ports/haptics_port.dart';
import 'package:gevurah/core/storage/progress_store.dart';
import 'package:gevurah/game/fight_controller.dart';
import 'package:gevurah/game/tuning.dart';
import 'package:gevurah/providers/achievements_provider.dart';
import 'package:gevurah/providers/fight_provider.dart';
import 'package:gevurah/providers/progress_provider.dart';

import '../fakes/fakes.dart';

/// A fake clock the test advances by hand.
class Clock {
  double now = 0;
  double read() => now;
}

enum Skill { perfect, never }

class Rig {
  Rig({this.skill = Skill.perfect, int seed = 11, String? struggle}) {
    final ProgressProvider progress = ProgressProvider(ProgressStore(FakeStorage(), starterCardIds: CardCatalog.starterIds));
    fight = FightProvider(progress: progress, achievements: AchievementsProvider(progress), clock: FakeClock(DateTime(2026, 11, 22)));
    fight.start(FightConfig(
      mode: FightMode.training,
      struggleId: struggle ?? StruggleCatalog.career.first.id,
      cardIds: const <String>[],
      stance: Stance.steady,
      seed: seed,
    ));
    controller = FightController(fight: fight, input: TapSwipeStrategy(), nowMs: clock.read, haptics: haptics, audio: audio);
    controller.events.listen(_onEvent);
  }

  final Skill skill;
  final Clock clock = Clock();
  final FakeHaptics haptics = FakeHaptics();
  final FakeAudio audio = FakeAudio();
  late final FightProvider fight;
  late final FightController controller;
  final List<FightEvent> events = <FightEvent>[];
  final List<Tapish> taps = <Tapish>[];
  bool combo = true;

  void _onEvent(FightEvent e) {
    events.add(e);
    switch (e) {
      case TelegraphStarted(:final double telegraphMs):
        if (skill == Skill.perfect) {
          taps.add(Tapish(clock.now + telegraphMs));
        }
      case OpeningOpened():
        if (skill == Skill.perfect) {
          final double beat = clock.now + GameTuning.openingDelayMs;
          taps.add(Tapish(beat));
          if (combo) {
            taps.add(Tapish(beat + 120));
          }
        }
      case ResponseRegistered():
        {}
      case ExchangeResolved():
        {}
      case FightPaused(:final PauseReason reason):
        if (reason == PauseReason.corner) {
          fight.endCorner();
          controller.resume();
        } else if (reason == PauseReason.tenCount) {
          fight.rise(skill == Skill.perfect ? 3 : 0);
          controller.resume();
        }
      case FightResumed():
        {}
      case PlayerPunched():
        {}
    }
  }


  /// Steps 8 ms at a time until [done] or the cap.
  void run({bool Function()? done, int maxSteps = 400000}) {
    controller.begin();
    for (int i = 0; i < maxSteps; i++) {
      clock.now += 8;
      controller.tick();
      for (final Tapish t in List<Tapish>.of(taps)) {
        if (clock.now >= t.at) {
          taps.remove(t);
          controller.gesture(RawGesture.tap(t.at));
        }
      }
      if (done != null ? done() : (fight.value?.finished ?? false) && controller.phase == ControllerPhase.paused) {
        return;
      }
    }
  }

  List<ExchangeRecord> get history => fight.value!.history;
}

class Tapish {
  Tapish(this.at);

  final double at;
}

void main() {
  reentrancyTests();
  test('a perfect player finishes a whole bout and the controller ends paused', () {
    final Rig r = Rig();
    r.run();
    expect(r.fight.value!.finished, isTrue);
    expect(r.controller.phase, ControllerPhase.paused);
    expect(r.events.whereType<ExchangeResolved>().length, r.history.length);
    expect(r.history.length, greaterThanOrEqualTo(3));
    expect(r.history.any((ExchangeRecord e) => e.outcome.quality == Quality.perfect), isTrue);
  });

  test('the same bout with the same inputs repeats exactly', () {
    final Rig a = Rig(seed: 21)..run();
    final Rig b = Rig(seed: 21)..run();
    expect(a.history.length, b.history.length);
    expect(a.fight.value!.state, b.fight.value!.state);
    expect(a.history.map((ExchangeRecord e) => e.offset.ms).toList(), b.history.map((ExchangeRecord e) => e.offset.ms).toList());
  });

  test('timestamps are judged against the beat, not the frame', () {
    final Rig r = Rig();
    r.run(done: () => resolvedAtLeast(r, 3));
    for (final ExchangeRecord e in r.history) {
      if (e.response != Response.takeIt) {
        expect(e.offset.ms.abs(), lessThan(1), reason: 'a tap stamped on the beat has no error, whatever the frame step');
      }
    }
  });

  test('a player who never answers takes every move and the bout still ends', () {
    final Rig r = Rig(skill: Skill.never)..run();
    expect(r.fight.value!.finished, isTrue);
    expect(r.history.every((ExchangeRecord e) => e.response == Response.takeIt), isTrue);
    expect(r.fight.value!.won, isFalse);
  });

  test('a good response with two taps records a combo counter', () {
    final Rig r = Rig()..run();
    expect(r.history.any((ExchangeRecord e) => e.counter == OpeningAction.combo), isTrue);
    final Rig single = Rig()..combo = false;
    single.run();
    expect(single.history.any((ExchangeRecord e) => e.counter == OpeningAction.strike), isTrue);
  });

  test('gestures outside a response or opening are ignored', () {
    final Rig r = Rig();
    r.controller.gesture(const RawGesture.tap(5));
    expect(r.history.length, 0);
    r.controller.begin();
    r.clock.now = 100;
    r.controller.tick();
    r.controller.gesture(const RawGesture.tap(100));
    expect(r.controller.phase, ControllerPhase.lead);
    expect(r.fight.value!.history, isEmpty);
  });

  test('the telegraph progress runs from 0 to 1 and feeds the notifier', () {
    final Rig r = Rig(skill: Skill.never);
    r.controller.begin();
    r.clock.now = GameTuning.resumeLeadMs + 1;
    r.controller.tick();
    expect(r.controller.phase, ControllerPhase.waitingResponse);
    final TelegraphStarted start = r.events.whereType<TelegraphStarted>().single;
    r.clock.now += start.telegraphMs / 2;
    r.controller.tick();
    expect(r.controller.telegraphProgress, closeTo(0.5, 0.01));
    expect(r.controller.progressNotifier.value, closeTo(0.5, 0.01));
    r.clock.now += start.telegraphMs;
    r.controller.tick();
    expect(r.controller.telegraphProgress, 1);
    expect(r.controller.currentMove, isNotNull);
  });

  test('pausing mid-exchange drops it without penalty and resume restarts the tell', () {
    final Rig r = Rig(skill: Skill.never);
    r.controller.begin();
    r.clock.now = GameTuning.resumeLeadMs + 1;
    r.controller.tick();
    expect(r.controller.phase, ControllerPhase.waitingResponse);
    r.controller.pause();
    expect(r.controller.phase, ControllerPhase.paused);
    expect(r.controller.pausedByUser, isTrue);
    expect(r.events.whereType<FightPaused>().last.reason, PauseReason.user);
    r.clock.now += 5000;
    r.controller.tick();
    expect(r.history, isEmpty);
    r.controller.pause();
    r.controller.resume();
    expect(r.controller.phase, ControllerPhase.lead);
    expect(r.controller.pausedByUser, isFalse);
    r.clock.now += GameTuning.resumeLeadMs + 1;
    r.controller.tick();
    expect(r.controller.phase, ControllerPhase.waitingResponse);
    expect(r.events.whereType<TelegraphStarted>().length, 2);
  });

  test('pause and resume do nothing when idle or over', () {
    final Rig r = Rig();
    r.controller.pause();
    r.controller.resume();
    expect(r.controller.phase, ControllerPhase.idle);
    r.run();
    r.controller.resume();
    expect(r.controller.phase, ControllerPhase.paused);
  });

  test('a Breath refills Stamina and costs the current exchange its opening', () {
    final Rig r = Rig();
    r.controller.begin();
    // Run to the first opening.
    for (int i = 0; i < 20000 && r.controller.phase != ControllerPhase.opening; i++) {
      r.clock.now += 8;
      r.controller.tick();
      for (final Tapish t in List<Tapish>.of(r.taps)) {
        if (r.clock.now >= t.at) {
          r.taps.remove(t);
          r.controller.gesture(RawGesture.tap(t.at));
        }
      }
    }
    expect(r.controller.phase, ControllerPhase.opening);
    final int charges = r.fight.value!.state.player.breathCharges;
    r.controller.breathe();
    expect(r.fight.value!.state.player.breathCharges, charges - 1);
    expect(r.fight.value!.state.player.stamina, greaterThanOrEqualTo(80));
    expect(r.history.last.counter, OpeningAction.none);
    expect(r.controller.phase, ControllerPhase.resolving);
  });

  test('a Breath in the response phase removes that exchange\'s opening', () {
    final Rig r = Rig();
    r.controller.begin();
    r.clock.now = GameTuning.resumeLeadMs + 1;
    r.controller.tick();
    r.controller.breathe();
    final double beat = r.clock.now + r.fight.telegraphMs!;
    r.clock.now = beat;
    r.controller.gesture(RawGesture.tap(beat));
    expect(r.events.whereType<ResponseRegistered>().single.opening, isFalse);
    expect(r.controller.phase, ControllerPhase.settling);
    r.controller.tick();
    expect(r.history.last.counter, OpeningAction.none);
  });

  test('Breath with none left, finished or paused does nothing', () {
    final Rig r = Rig();
    r.controller.breathe();
    r.controller.begin();
    r.controller.pause();
    r.controller.breathe();
    r.controller.resume();
    r.fight.breathe();
    final int left = r.fight.value!.state.player.breathCharges;
    r.controller.breathe();
    expect(r.fight.value!.state.player.breathCharges, left);
  });

  test('tells, hits and answers reach haptics and sound', () {
    final Rig r = Rig()..run();
    expect(r.haptics.played, contains(HapticKind.tellPulse));
    expect(r.haptics.played, contains(HapticKind.perfect));
    expect(r.audio.played.any(<String>[GameTuning.soundTell, GameTuning.soundTellHeavy, GameTuning.soundTellFlurry].contains), isTrue);
    expect(r.audio.played, contains(GameTuning.soundGuard));
    expect(r.audio.preloaded, GameTuning.allSounds);
  });

  test('the controller runs without haptics or audio', () {
    final Rig r = Rig();
    final FightController bare = FightController(fight: r.fight, input: TapSwipeStrategy(), nowMs: r.clock.read);
    bare.begin();
    r.clock.now = GameTuning.resumeLeadMs + 1;
    bare.tick();
    expect(bare.phase, ControllerPhase.waitingResponse);
    bare.dispose();
  });

  test('the real clock moves forward', () async {
    final double Function() clock = FightController.stopwatchClock();
    final double a = clock();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(clock(), greaterThan(a));
  });

  test('a swipe answers with a slip', () {
    final Rig r = Rig(skill: Skill.never);
    r.controller.begin();
    r.clock.now = GameTuning.resumeLeadMs + 1;
    r.controller.tick();
    final double beat = r.clock.now + r.fight.telegraphMs!;
    r.clock.now = beat;
    r.controller.gesture(RawGesture.swipe(beat, dx: 90));
    expect(r.events.whereType<ResponseRegistered>().single.response, Response.slip);
    expect(r.audio.played, contains(GameTuning.soundSlip));
  });
}

bool resolvedAtLeast(Rig r, int n) => r.history.length >= n;

void reentrancyTests() {
  test('a listener that resumes inside a pause event does not break delivery order', () {
    final Rig r = Rig();
    r.run();
    final List<FightEvent> ev = r.events;
    final int pausedAt = ev.indexWhere((FightEvent e) => e is FightPaused);
    expect(pausedAt, greaterThan(-1));
    // Whatever a pause caused (a resume) comes after the pause itself.
    for (int i = 0; i < ev.length; i++) {
      if (ev[i] is FightResumed) {
        expect(ev.take(i).whereType<FightPaused>(), isNotEmpty);
      }
    }
  });
}
