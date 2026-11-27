import 'package:flutter/foundation.dart';

import '../core/catalog/struggle_catalog.dart';
import '../core/logic/exchange_resolver.dart';
import '../core/logic/fight_rules.dart';
import '../core/logic/modifiers.dart';
import '../core/logic/progression_rules.dart';
import '../core/logic/seeded_rng.dart';
import '../core/logic/struggle_ai.dart';
import '../core/logic/struggle_tuning.dart';
import '../core/models/beat_offset.dart';
import '../core/models/daily_challenge.dart';
import '../core/models/exchange_outcome.dart';
import '../core/models/exchange_record.dart';
import '../core/models/fight_config.dart';
import '../core/models/fight_state.dart';
import '../core/models/move_def.dart';
import '../core/models/player_state.dart';
import '../core/models/stance.dart';
import '../core/models/struggle_def.dart';
import '../core/ports/clock_port.dart';
import '../core/logic/daily_seed.dart';
import 'achievements_provider.dart';
import 'progress_provider.dart';

/// Percent of a struggle's Weight used in Sparring at each difficulty.
abstract final class DifficultyTuning {
  static const int gentlePercent = 80;
  static const int standardPercent = 100;
  static const int hardPercent = 125;

  static int percent(Difficulty d) {
    switch (d) {
      case Difficulty.gentle:
        return gentlePercent;
      case Difficulty.standard:
        return standardPercent;
      case Difficulty.hard:
        return hardPercent;
    }
  }
}

/// A stance change made in the corner. Recorded with the bout so the same
/// config, the same inputs and the same changes always give the same bout.
class StanceChange {
  const StanceChange({required this.exchangeIndex, required this.stance});

  /// The index of the next exchange when the change was made.
  final int exchangeIndex;
  final Stance stance;
}

/// One snapshot of a bout in progress, for the screen and the Flame world.
class FightView {
  const FightView({
    required this.config,
    required this.struggle,
    required this.state,
    required this.history,
    required this.move,
    this.stanceChanges = const <StanceChange>[],
  });

  final FightConfig config;
  final StruggleDef struggle;
  final FightState state;
  final List<ExchangeRecord> history;

  /// The struggle's current move, or null in a pause (corner, ten-count, end).
  final MoveDef? move;

  /// Stance changes made in the corner, in order.
  final List<StanceChange> stanceChanges;

  /// The stance in force now.
  Stance get stance => stanceChanges.isEmpty ? config.stance : stanceChanges.last.stance;

  bool get finished => state.isFinished;
  bool get won => ProgressionRules.isWin(state.end);
  int get stars => ProgressionRules.stars(state, history);
}

/// What finishing a bout changed, for the result screen.
class FightFinish {
  const FightFinish({required this.view, required this.applied, required this.newAchievements});

  final FightView view;

  /// Null for the Daily Bout, which is recorded by date instead.
  final FightResultApplied? applied;
  final List<String> newAchievements;
}

/// Runs one bout. The screen supplies the player's timing; every outcome is
/// decided by the pure core. The same config and the same inputs always give
/// the same bout.
class FightProvider extends ValueNotifier<FightView?> {
  FightProvider({required this.progress, required this.achievements, required this.clock}) : super(null);

  final ProgressProvider progress;
  final AchievementsProvider achievements;
  final ClockPort clock;

  SeededRng? _aiRng;
  Modifiers _modifiers = Modifiers.none;
  FightFinish? _finish;
  DailyChallenge? _daily;

  /// Begins a bout. Returns false if the struggle is unknown.
  bool start(FightConfig config, {DailyChallenge? daily}) {
    final StruggleDef? def = StruggleCatalog.byId(config.struggleId);
    if (def == null) {
      value = null;
      return false;
    }
    _finish = null;
    _daily = config.mode == FightMode.daily ? daily : null;
    _aiRng = SeededRng(config.seed).fork('ai');
    _modifiers = Modifiers.from(cardIds: config.cardIds, stance: config.stance);
    final int percent = config.mode == FightMode.sparring ? DifficultyTuning.percent(config.difficulty) : 100;
    final int base = (def.weight * percent / 100).round();
    final int weight = config.mode == FightMode.endurance ? base * FightTuning.enduranceWeightFactor : base;
    final bool bonusAllowed = config.mode != FightMode.daily && config.mode != FightMode.training;
    final int breath = bonusAllowed ? config.extraBreath.clamp(0, 1) : 0;
    final int stamina = config.easy
        ? FightTuning.endlessStamina - PlayerState.maxStamina
        : config.mode == FightMode.endurance
            ? config.extraStamina.clamp(0, FightTuning.rewardStamina)
            : 0;
    final FightState state = FightState.initial(weight, player: PlayerState.boosted(extraBreath: breath, extraStamina: stamina));
    value = FightView(config: config, struggle: def, state: state, history: const <ExchangeRecord>[], move: _pick(def, const <ExchangeRecord>[], config));
    return true;
  }

  MoveDef _pick(StruggleDef def, List<ExchangeRecord> history, FightConfig config) {
    final MoveDef move = StruggleAi.nextMove(def, history, _aiRng!);
    if (config.mode != FightMode.endurance) {
      return move;
    }
    int cut = (history.length ~/ FightTuning.endurancePaceEvery) * FightTuning.endurancePaceStepMs;
    if (cut > FightTuning.endurancePaceMaxCutMs) {
      cut = FightTuning.endurancePaceMaxCutMs;
    }
    final int ms = move.telegraphMs - cut;
    return cut == 0 ? move : move.copyWith(telegraphMs: ms < StruggleAi.minTelegraphMs ? StruggleAi.minTelegraphMs : ms);
  }

  /// How long the current move telegraphs, with the equipped cards and stance.
  int? get telegraphMs {
    final MoveDef? m = value?.move;
    return m == null ? null : _modifiers.telegraphFor(m);
  }

  void _set(FightState state, List<ExchangeRecord> history) {
    final FightView v = value!;
    final bool needsMove = !state.isFinished && state.phase != FightPhase.tenCount && state.phase != FightPhase.corner;
    value = FightView(
      config: v.config,
      struggle: v.struggle,
      state: state,
      history: history,
      move: needsMove ? _pick(v.struggle, history, v.config) : null,
      stanceChanges: v.stanceChanges,
    );
  }

  /// The player's answer to the current move. [offset] is the timing of the
  /// response; [counter] and [strikeOffset] are used only in an opening.
  ExchangeRecord? respond({
    required Response response,
    required BeatOffset offset,
    OpeningAction counter = OpeningAction.none,
    BeatOffset? strikeOffset,
  }) {
    final FightView? v = value;
    final MoveDef? move = v?.move;
    if (v == null || move == null || v.finished) {
      return null;
    }
    final ExchangeOutcome outcome = _resolve(v, move, response, offset, counter, strikeOffset);
    final ExchangeRecord record = ExchangeRecord(
      index: v.state.exchangeIndex,
      round: v.state.round,
      move: move,
      response: response,
      offset: offset,
      outcome: outcome,
      counter: counter,
      strikeOffset: strikeOffset,
    );
    final List<ExchangeRecord> history = <ExchangeRecord>[...v.history, record];
    _set(FightRules.apply(v.state, record, v.struggle, endless: v.config.mode == FightMode.endurance), history);
    return record;
  }

  ExchangeOutcome _resolve(FightView v, MoveDef move, Response response, BeatOffset offset, OpeningAction counter, BeatOffset? strikeOffset) {
    return ExchangeResolver.resolve(
      move: move,
      response: response,
      offset: offset,
      counter: counter,
      strikeOffset: strikeOffset,
      context: ExchangeContext(
        modifiers: _modifiers,
        player: v.state.player,
        assist: v.config.timingAssist,
        costly: v.struggle.hasTrait(StruggleTrait.costly),
        incomingDamagePercent: StruggleTuning.incomingDamagePercent(v.struggle),
        struggleDamageTakenPercent: StruggleAi.damageTakenPercent(v.struggle, v.history),
      ),
    );
  }

  /// What a response would do, without applying it. The fight controller uses
  /// it to know at once whether the response opens an attack window.
  ExchangeOutcome? preview({required Response response, required BeatOffset offset}) {
    final FightView? v = value;
    final MoveDef? move = v?.move;
    if (v == null || move == null || v.finished) {
      return null;
    }
    return _resolve(v, move, response, offset, OpeningAction.none, null);
  }

  /// The ten-count: [goodTaps] timed taps bring the player back up.
  void rise(int goodTaps) {
    final FightView? v = value;
    if (v == null || v.state.phase != FightPhase.tenCount) {
      return;
    }
    _set(FightRules.rise(v.state, goodTaps, endless: v.config.mode == FightMode.endurance), v.history);
  }

  /// The corner between rounds ends and the next round starts.
  void endCorner() {
    final FightView? v = value;
    if (v == null || v.state.phase != FightPhase.corner) {
      return;
    }
    _set(FightRules.endCorner(v.state, v.struggle), v.history);
  }

  /// Changes stance in the corner, for the rest of the bout. The change is
  /// recorded in the view. Returns false outside the corner.
  bool changeStance(Stance stance) {
    final FightView? v = value;
    if (v == null || v.state.phase != FightPhase.corner) {
      return false;
    }
    if (stance == v.stance) {
      return true;
    }
    _modifiers = Modifiers.from(cardIds: v.config.cardIds, stance: stance);
    value = FightView(
      config: v.config,
      struggle: v.struggle,
      state: v.state,
      history: v.history,
      move: v.move,
      stanceChanges: <StanceChange>[...v.stanceChanges, StanceChange(exchangeIndex: v.state.exchangeIndex, stance: stance)],
    );
    return true;
  }

  /// Uses a Breath: Stamina back to full. Does nothing with none left.
  void breathe() {
    final FightView? v = value;
    if (v == null || v.finished) {
      return;
    }
    final FightState next = FightRules.breathe(v.state);
    if (next != v.state) {
      value = FightView(config: v.config, struggle: v.struggle, state: next, history: v.history, move: v.move, stanceChanges: v.stanceChanges);
    }
  }

  /// Records a finished bout once: the career, the daily, and achievements.
  /// Calling it again returns the same result.
  Future<FightFinish?> finish() async {
    final FightView? v = value;
    if (v == null || !v.finished) {
      return null;
    }
    final FightFinish? done = _finish;
    if (done != null) {
      return done;
    }
    FightResultApplied? applied;
    if (v.config.mode == FightMode.daily) {
      final DailyChallenge? d = _daily;
      if (d != null) {
        await progress.applyDaily(d, completed: v.won, stars: v.stars);
      }
    } else {
      applied = await progress.applyFightResult(v.config, v.state, v.history);
    }
    final List<String> fresh = await achievements.evaluate(
      finalState: v.state,
      history: v.history,
      todayKey: DailySeed.dateKey(clock.now()),
    );
    return _finish = FightFinish(view: v, applied: applied, newAchievements: fresh);
  }

  /// Leaves the bout without recording anything.
  void abandon() {
    _finish = null;
    value = null;
  }
}
