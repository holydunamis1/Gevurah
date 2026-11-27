import '../models/exchange_record.dart';
import '../models/fight_state.dart';
import '../models/player_state.dart';
import '../models/struggle_def.dart';

/// Tuning for rounds, downs and the decision. These are tuning values.
abstract final class FightTuning {
  static const int exchangesPerRound = 18;
  static const int downsToEnd = 3;

  /// Extra starting Stamina (and cap) from the Endurance rewarded ad. A
  /// starting number for tuning.
  static const int rewardStamina = 20;

  /// The one-tap game's struggles have this many times their Weight, so a bout
  /// lasts a minute or more rather than a few exchanges.
  static const int easyWeightFactor = 3;

  /// Starting Stamina in the one-tap game, so it never runs out.
  static const int endlessStamina = 100000;

  /// Percent of the struggle's starting Weight it gets back when it rises once.
  static const int riseRestorePercent = 30;

  /// Resolve restored after a ten-count: base plus per good tap, capped.
  static const int riseBaseResolve = 20;
  static const int risePerTap = 6;
  static const int riseMaxResolve = 60;

  /// Stamina restored by the corner between rounds.
  static const int cornerStaminaRefill = 60;
  static const int cornerResolveRefill = 15;

  /// Points charged against the player for each down in a decision.
  static const int pointsPerDown = 15;

  /// Endurance: the struggle never runs out of Weight (its Weight is
  /// multiplied by this), and each [endurancePaceEvery] exchanges every tell
  /// is [endurancePaceStepMs] shorter, up to [endurancePaceMaxCutMs].
  static const int enduranceWeightFactor = 1000;
  static const int endurancePaceEvery = 6;
  static const int endurancePaceStepMs = 15;
  static const int endurancePaceMaxCutMs = 200;
}

/// The pure rules that move a bout from one snapshot to the next.
abstract final class FightRules {
  /// Applies one resolved exchange. Callers pass the record the resolver made.
  /// With [endless] (Endurance) the bout has no last round and no decision: it
  /// ends only when the player is down for the last time.
  static FightState apply(FightState state, ExchangeRecord record, StruggleDef struggle, {bool endless = false}) {
    if (state.isFinished) {
      return state;
    }
    int weight = state.weight - record.outcome.damageDealt;
    PlayerState player = state.player.copyWith(
      resolve: state.player.resolve - record.outcome.damageTaken,
      stamina: (state.player.stamina + record.outcome.staminaChange).clamp(0, state.player.staminaCap),
    );
    int rises = state.struggleRises;
    final int nextIndex = state.exchangeIndex + 1;

    if (weight <= 0) {
      if (struggle.hasTrait(StruggleTrait.resilient) && rises == 0) {
        rises = 1;
        weight = (state.startingWeight * FightTuning.riseRestorePercent) ~/ 100;
      } else {
        return state.copyWith(
          weight: 0,
          player: player,
          exchangeIndex: nextIndex,
          phase: FightPhase.finished,
          end: FightEnd.struggleDefeated,
          struggleRises: rises,
        );
      }
    }

    if (player.isDown) {
      player = player.copyWith(resolve: 0, downs: player.downs + 1);
      if (player.downs >= FightTuning.downsToEnd) {
        return state.copyWith(
          weight: weight,
          player: player,
          exchangeIndex: nextIndex,
          phase: FightPhase.finished,
          end: FightEnd.playerDown,
          struggleRises: rises,
        );
      }
      return state.copyWith(
        weight: weight,
        player: player,
        exchangeIndex: nextIndex,
        phase: FightPhase.tenCount,
        struggleRises: rises,
      );
    }

    final bool roundOver = nextIndex >= state.round * FightTuning.exchangesPerRound;
    if (roundOver) {
      if (!endless && state.round >= FightState.roundsPerBout) {
        return state.copyWith(
          weight: weight,
          player: player,
          exchangeIndex: nextIndex,
          phase: FightPhase.finished,
          end: decision(state.startingWeight, weight, player),
          struggleRises: rises,
        );
      }
      return state.copyWith(
        weight: weight,
        player: player,
        exchangeIndex: nextIndex,
        phase: FightPhase.corner,
        struggleRises: rises,
      );
    }

    return state.copyWith(
      weight: weight,
      player: player,
      exchangeIndex: nextIndex,
      phase: FightPhase.telegraph,
      struggleRises: rises,
    );
  }

  /// Resolves the ten-count after [goodTaps] timed taps. Resolve comes back
  /// partly; the bout carries on from the next exchange (or the corner).
  static FightState rise(FightState state, int goodTaps, {bool endless = false}) {
    if (state.phase != FightPhase.tenCount) {
      return state;
    }
    final int taps = goodTaps < 0 ? 0 : goodTaps;
    int resolve = FightTuning.riseBaseResolve + taps * FightTuning.risePerTap;
    if (resolve > FightTuning.riseMaxResolve) {
      resolve = FightTuning.riseMaxResolve;
    }
    final PlayerState player = state.player.copyWith(resolve: resolve);
    final bool roundOver = state.exchangeIndex >= state.round * FightTuning.exchangesPerRound;
    if (roundOver) {
      if (!endless && state.round >= FightState.roundsPerBout) {
        return state.copyWith(
          player: player,
          phase: FightPhase.finished,
          end: decision(state.startingWeight, state.weight, player),
        );
      }
      return state.copyWith(player: player, phase: FightPhase.corner);
    }
    return state.copyWith(player: player, phase: FightPhase.telegraph);
  }

  /// Uses one Breath: restores stamina in full. Does nothing with none left.
  static FightState breathe(FightState state) {
    if (state.isFinished || state.player.breathCharges <= 0) {
      return state;
    }
    return state.copyWith(
      player: state.player.copyWith(
        stamina: state.player.staminaCap,
        breathCharges: state.player.breathCharges - 1,
      ),
    );
  }

  /// Ends the corner: refills stamina (halved against Crowding), a little
  /// Resolve, a fresh Breath, and starts the next round.
  static FightState endCorner(FightState state, StruggleDef struggle) {
    if (state.phase != FightPhase.corner) {
      return state;
    }
    final bool crowded = struggle.hasTrait(StruggleTrait.crowding);
    final int refill = crowded ? FightTuning.cornerStaminaRefill ~/ 2 : FightTuning.cornerStaminaRefill;
    final PlayerState p = state.player;
    return state.copyWith(
      round: state.round + 1,
      phase: FightPhase.telegraph,
      player: p.copyWith(
        stamina: (p.stamina + refill).clamp(0, p.staminaCap),
        resolve: (p.resolve + FightTuning.cornerResolveRefill).clamp(0, PlayerState.maxResolve),
        breathCharges: PlayerState.breathPerRound,
      ),
    );
  }

  /// Points decision after round three. A tie goes to the player.
  static FightEnd decision(int startingWeight, int weight, PlayerState player) {
    final int playerPoints = startingWeight <= 0 ? 0 : ((startingWeight - weight) * 100) ~/ startingWeight;
    final int struggleStrength = (PlayerState.maxResolve - player.resolve) + player.downs * FightTuning.pointsPerDown;
    return playerPoints >= struggleStrength ? FightEnd.decisionWon : FightEnd.decisionLost;
  }
}
