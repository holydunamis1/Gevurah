import '../catalog/card_catalog.dart';
import '../models/move_def.dart';
import '../models/stance.dart';
import '../models/verse_card_def.dart';

/// The numbers that the equipped verse cards and the stance add to the rules.
/// Every field is a sum over the cards and the stance; zero means no change.
class Modifiers {
  const Modifiers({
    this.guardWindowDeltaMs = 0,
    this.strikeWindowDeltaMs = 0,
    this.strikeDamagePercent = 0,
    this.perfectStrikeDamagePercent = 0,
    this.comboStaminaDelta = 0,
    this.perfectGuardStaminaReturn = 0,
    this.goodGuardReductionDeltaPercent = 0,
    this.telegraphDeltaMs = 0,
    this.lowResolveDamageReducePercent = 0,
    this.staminaRegenPercent = 0,
  });

  /// Turns equipped cards and a stance into modifiers. Unknown ids are ignored.
  factory Modifiers.from({required List<String> cardIds, required Stance stance}) {
    int guardWindow = stance.guardWindowDeltaMs;
    int strikeWindow = 0;
    int strikeDamage = stance.strikeDamagePercent;
    int perfectStrike = 0;
    int comboStamina = 0;
    int guardReturn = 0;
    int goodGuard = 0;
    int telegraph = stance.telegraphDeltaMs;
    int lowResolve = 0;
    int regen = stance.staminaRegenPercent;
    for (final String id in cardIds) {
      final VerseCardDef? card = CardCatalog.byId(id);
      if (card == null) {
        continue;
      }
      final CardModifier m = card.modifier;
      perfectStrike += m.perfectStrikeDamagePercent;
      comboStamina += m.comboStaminaDelta;
      guardReturn += m.perfectGuardStaminaReturn;
      goodGuard += m.goodGuardReductionDeltaPercent;
      telegraph += m.telegraphDeltaMs;
      strikeWindow += m.strikeWindowDeltaMs;
      lowResolve += m.lowResolveDamageReducePercent;
      regen += m.staminaRegenPercent;
    }
    return Modifiers(
      guardWindowDeltaMs: guardWindow,
      strikeWindowDeltaMs: strikeWindow,
      strikeDamagePercent: strikeDamage,
      perfectStrikeDamagePercent: perfectStrike,
      comboStaminaDelta: comboStamina,
      perfectGuardStaminaReturn: guardReturn,
      goodGuardReductionDeltaPercent: goodGuard,
      telegraphDeltaMs: telegraph,
      lowResolveDamageReducePercent: lowResolve,
      staminaRegenPercent: regen,
    );
  }

  static const Modifiers none = Modifiers();

  /// Added to both guard windows, in ms (negative narrows).
  final int guardWindowDeltaMs;

  /// Added to both strike windows, in ms (negative narrows).
  final int strikeWindowDeltaMs;

  /// Percent change to all strike damage (stance).
  final int strikeDamagePercent;

  /// Extra percent damage on perfect strikes (Strike card).
  final int perfectStrikeDamagePercent;

  /// Extra Stamina a Combo costs (Strike card).
  final int comboStaminaDelta;

  /// Stamina returned by a perfect guard (Guard card).
  final int perfectGuardStaminaReturn;

  /// Change, in percentage points, to the damage a good guard blocks (negative blocks less).
  final int goodGuardReductionDeltaPercent;

  /// Added to the visible telegraph, in ms.
  final int telegraphDeltaMs;

  /// Percent less damage taken while Resolve is below 30 (Steadiness card).
  final int lowResolveDamageReducePercent;

  /// Percent change to Stamina regeneration.
  final int staminaRegenPercent;

  /// The telegraph the player sees for [move].
  int telegraphFor(MoveDef move) {
    final int t = move.telegraphMs + telegraphDeltaMs;
    return t < 200 ? 200 : t;
  }

  @override
  bool operator ==(Object other) {
    return other is Modifiers &&
        other.guardWindowDeltaMs == guardWindowDeltaMs &&
        other.strikeWindowDeltaMs == strikeWindowDeltaMs &&
        other.strikeDamagePercent == strikeDamagePercent &&
        other.perfectStrikeDamagePercent == perfectStrikeDamagePercent &&
        other.comboStaminaDelta == comboStaminaDelta &&
        other.perfectGuardStaminaReturn == perfectGuardStaminaReturn &&
        other.goodGuardReductionDeltaPercent == goodGuardReductionDeltaPercent &&
        other.telegraphDeltaMs == telegraphDeltaMs &&
        other.lowResolveDamageReducePercent == lowResolveDamageReducePercent &&
        other.staminaRegenPercent == staminaRegenPercent;
  }

  @override
  int get hashCode => Object.hash(
        guardWindowDeltaMs,
        strikeWindowDeltaMs,
        strikeDamagePercent,
        perfectStrikeDamagePercent,
        comboStaminaDelta,
        perfectGuardStaminaReturn,
        goodGuardReductionDeltaPercent,
        telegraphDeltaMs,
        lowResolveDamageReducePercent,
        staminaRegenPercent,
      );
}
