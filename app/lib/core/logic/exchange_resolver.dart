import '../models/beat_offset.dart';
import '../models/exchange_outcome.dart';
import '../models/exchange_record.dart';
import '../models/move_def.dart';
import '../models/player_state.dart';
import 'modifiers.dart';
import 'stamina.dart';
import 'timing_judge.dart';

/// Tuning starting values for one exchange. The balance simulation adjusts them.
abstract final class ExchangeTuning {
  /// Strike and Combo base damage.
  static const int strikeDamage = 8;
  static const int comboDamage = 14;

  /// Opening size: how much of the counter a perfect or good response earns, in percent.
  static const int perfectOpeningPercent = 100;
  static const int goodOpeningPercent = 70;

  /// Strike timing multiplier, in percent: perfect, good, miss.
  static const int perfectStrikePercent = 125;
  static const int goodStrikePercent = 100;
  static const int missStrikePercent = 0;

  /// Resolve below this counts as low for the Steadiness card.
  static const int lowResolveBelow = 30;
}

/// Everything about one exchange that is not the move or the timing.
class ExchangeContext {
  const ExchangeContext({
    this.modifiers = Modifiers.none,
    this.player = const PlayerState.initial(),
    this.assist = false,
    this.costly = false,
    this.struggleDamageTakenPercent = 100,
    this.incomingDamagePercent = 100,
  });

  final Modifiers modifiers;
  final PlayerState player;

  /// The Timing assist setting.
  final bool assist;

  /// Every action costs double Stamina (Exhaustion).
  final bool costly;

  /// Percent of counter damage the struggle takes (Shame's guard, 100 is normal).
  final int struggleDamageTakenPercent;

  /// Percent of the move's damage that reaches the player, a per-struggle
  /// balance value from StruggleTuning (100 is unchanged).
  final int incomingDamagePercent;
}

/// Resolves one exchange. A pure function: the same inputs always give the same
/// outcome. It never reads time, randomness or any state outside its arguments.
abstract final class ExchangeResolver {
  /// The fraction of a move's damage taken after [response] at quality [q], in percent.
  static int takenPercent(MoveKind kind, Response response, Quality q, Modifiers m) {
    if (response == Response.takeIt || q == Quality.miss) {
      return 100;
    }
    final bool perfect = q == Quality.perfect;
    if (response == Response.guard) {
      if (kind == MoveKind.heavy) {
        return perfect ? 25 : 65;
      }
      if (perfect) {
        return 0;
      }
      final int p = 50 - m.goodGuardReductionDeltaPercent;
      return p < 0 ? 0 : (p > 100 ? 100 : p);
    }
    // Slip.
    if (kind == MoveKind.flurry || kind == MoveKind.ping) {
      return perfect ? 50 : 75;
    }
    return perfect ? 0 : 50;
  }

  /// Resolves the exchange for [move] given the player's [response] timing
  /// [offset], and the opening action [counter] with its timing [strikeOffset].
  static ExchangeOutcome resolve({
    required MoveDef move,
    required Response response,
    required BeatOffset offset,
    OpeningAction counter = OpeningAction.none,
    BeatOffset? strikeOffset,
    ExchangeContext context = const ExchangeContext(),
  }) {
    final Modifiers m = context.modifiers;
    final PlayerState player = context.player;
    final bool staminaEmpty = player.stamina <= 0;
    int stamina = 0;

    // 1. The response: its cost and its timing quality.
    Quality quality = Quality.miss;
    if (response != Response.takeIt) {
      final StaminaAction action = response == Response.guard ? StaminaAction.guard : StaminaAction.slip;
      final int cost = StaminaRules.cost(action, m, costly: context.costly);
      stamina -= cost > player.stamina ? player.stamina : cost;
      final Windows w = TimingJudge.responseWindows(
        m,
        isGuard: response == Response.guard,
        assist: context.assist,
        staminaEmpty: staminaEmpty,
      );
      quality = TimingJudge.judge(offset, w);
    } else {
      stamina += StaminaRules.takeItGain;
    }

    // 2. Damage and Stamina drain taken.
    final bool isFake = move.kind == MoveKind.fake;
    final bool isBait = move.kind == MoveKind.bait;
    int takenPercent = ExchangeResolver.takenPercent(move.kind, response, quality, m);
    if (isFake) {
      takenPercent = 0;
    }
    final bool baitSprung = isBait && response != Response.takeIt && quality != Quality.miss;
    if (baitSprung) {
      takenPercent = 0;
    }
    double damage = move.damage * move.hits * takenPercent / 100 * context.incomingDamagePercent / 100;
    if (player.resolve < ExchangeTuning.lowResolveBelow && m.lowResolveDamageReducePercent > 0) {
      damage = damage * (100 - m.lowResolveDamageReducePercent) / 100;
    }
    int damageTaken = damage.round();
    final int drain = (move.staminaDrain * takenPercent / 100).round();
    stamina -= drain;

    if (quality == Quality.perfect && response != Response.takeIt && !isFake) {
      stamina += StaminaRules.perfectBonus;
      if (response == Response.guard) {
        stamina += m.perfectGuardStaminaReturn;
      }
    }
    stamina += StaminaRules.regen(m);

    // 3. The opening.
    bool opening = response != Response.takeIt && quality != Quality.miss && !isFake;
    Quality reported = quality;
    if (isFake && response == Response.takeIt) {
      // Reading a fake and not reacting is rewarded with an opening.
      opening = true;
      reported = Quality.good;
    }

    // 4. The counter.
    int damageDealt = 0;
    if (opening && counter != OpeningAction.none) {
      final StaminaAction action = counter == OpeningAction.strike ? StaminaAction.strike : StaminaAction.combo;
      final int cost = StaminaRules.cost(action, m, costly: context.costly);
      final int available = player.stamina + stamina;
      if (available >= cost && available > 0) {
        stamina -= cost;
        if (baitSprung) {
          // Striking into a bait is the trap.
          damageTaken += (move.damage * move.hits * context.incomingDamagePercent / 100).round();
        } else {
          final Windows sw = TimingJudge.strikeWindows(m, assist: context.assist);
          final Quality sq = strikeOffset == null ? reported : TimingJudge.judge(strikeOffset, sw);
          final int base = counter == OpeningAction.strike ? ExchangeTuning.strikeDamage : ExchangeTuning.comboDamage;
          final int openingPercent = reported == Quality.perfect
              ? ExchangeTuning.perfectOpeningPercent
              : ExchangeTuning.goodOpeningPercent;
          int strikePercent;
          switch (sq) {
            case Quality.perfect:
              strikePercent = ExchangeTuning.perfectStrikePercent + m.perfectStrikeDamagePercent;
            case Quality.good:
              strikePercent = ExchangeTuning.goodStrikePercent;
            case Quality.miss:
              strikePercent = ExchangeTuning.missStrikePercent;
          }
          double d = base * openingPercent / 100 * strikePercent / 100;
          d = d * (100 + m.strikeDamagePercent) / 100;
          d = d * context.struggleDamageTakenPercent / 100;
          damageDealt = d < 0 ? 0 : d.round();
        }
      }
    }

    return ExchangeOutcome(
      quality: reported,
      damageTaken: damageTaken,
      damageDealt: damageDealt,
      staminaChange: stamina,
      opening: opening,
    );
  }
}
