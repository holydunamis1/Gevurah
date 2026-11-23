
import '../core/models/move_def.dart';
import '../core/models/stance.dart';
import '../core/models/verse_card_def.dart';
import '../core/models/verse_ref.dart';
import 'app_localizations.dart';

/// Lookups from stable ids to localized text, so screens never build a key by
/// hand. A missing id returns the id itself and a test fails if any catalog id
/// is missing.
extension AppStrings on AppLocalizations {
  String struggleName(String id) {
    switch (id) {
      case 'fear':
        return struggle_fear;
      case 'worry':
        return struggle_worry;
      case 'anger':
        return struggle_anger;
      case 'impatience':
        return struggle_impatience;
      case 'loneliness':
        return struggle_loneliness;
      case 'discouragement':
        return struggle_discouragement;
      case 'exhaustion':
        return struggle_exhaustion;
      case 'envy':
        return struggle_envy;
      case 'doubt':
        return struggle_doubt;
      case 'temptation':
        return struggle_temptation;
      case 'rejection':
        return struggle_rejection;
      case 'bitterness':
        return struggle_bitterness;
      case 'pride':
        return struggle_pride;
      case 'shame':
        return struggle_shame;
      case 'failure':
        return struggle_failure;
      case 'giving_up':
        return struggle_giving_up;
      case 'complaining':
        return struggle_complaining;
      case 'procrastination':
        return struggle_procrastination;
      case 'distraction':
        return struggle_distraction;
      case 'money_pressure':
        return struggle_money_pressure;
      case 'comparison':
        return struggle_comparison;
      case 'regret':
        return struggle_regret;
      case 'indecision':
        return struggle_indecision;
      case 'overwhelm':
        return struggle_overwhelm;
      case 'perfectionism':
        return struggle_perfectionism;
      case 'unforgiveness':
        return struggle_unforgiveness;
      default:
        return id;
    }
  }

  String struggleTell(String id) {
    switch (id) {
      case 'fear':
        return struggle_fear_tell;
      case 'worry':
        return struggle_worry_tell;
      case 'anger':
        return struggle_anger_tell;
      case 'impatience':
        return struggle_impatience_tell;
      case 'loneliness':
        return struggle_loneliness_tell;
      case 'discouragement':
        return struggle_discouragement_tell;
      case 'exhaustion':
        return struggle_exhaustion_tell;
      case 'envy':
        return struggle_envy_tell;
      case 'doubt':
        return struggle_doubt_tell;
      case 'temptation':
        return struggle_temptation_tell;
      case 'rejection':
        return struggle_rejection_tell;
      case 'bitterness':
        return struggle_bitterness_tell;
      case 'pride':
        return struggle_pride_tell;
      case 'shame':
        return struggle_shame_tell;
      case 'failure':
        return struggle_failure_tell;
      case 'giving_up':
        return struggle_giving_up_tell;
      case 'complaining':
        return struggle_complaining_tell;
      case 'procrastination':
        return struggle_procrastination_tell;
      case 'distraction':
        return struggle_distraction_tell;
      case 'money_pressure':
        return struggle_money_pressure_tell;
      case 'comparison':
        return struggle_comparison_tell;
      case 'regret':
        return struggle_regret_tell;
      case 'indecision':
        return struggle_indecision_tell;
      case 'overwhelm':
        return struggle_overwhelm_tell;
      case 'perfectionism':
        return struggle_perfectionism_tell;
      case 'unforgiveness':
        return struggle_unforgiveness_tell;
      default:
        return id;
    }
  }

  String moveName(MoveKind kind) {
    switch (kind) {
      case MoveKind.strike:
        return move_strike;
      case MoveKind.flurry:
        return move_flurry;
      case MoveKind.heavy:
        return move_heavy;
      case MoveKind.ping:
        return move_ping;
      case MoveKind.fake:
        return move_fake;
      case MoveKind.bait:
        return move_bait;
      case MoveKind.drain:
        return move_drain;
    }
  }

  String stanceName(Stance stance) {
    switch (stance) {
      case Stance.steady:
        return stance_steady;
      case Stance.bold:
        return stance_bold;
      case Stance.patient:
        return stance_patient;
    }
  }

  String stanceHint(Stance stance) {
    switch (stance) {
      case Stance.steady:
        return stance_steady_hint;
      case Stance.bold:
        return stance_bold_hint;
      case Stance.patient:
        return stance_patient_hint;
    }
  }

  String cardTypeName(CardType type) {
    switch (type) {
      case CardType.strike:
        return cardType_strike;
      case CardType.guard:
        return cardType_guard;
      case CardType.insight:
        return cardType_insight;
      case CardType.steadiness:
        return cardType_steadiness;
    }
  }

  String cardEffect(CardType type) {
    final CardModifier m = type.modifier;
    switch (type) {
      case CardType.strike:
        return cardEffect_strike(m.perfectStrikeDamagePercent);
      case CardType.guard:
        return cardEffect_guard(m.perfectGuardStaminaReturn);
      case CardType.insight:
        return cardEffect_insight(m.telegraphDeltaMs);
      case CardType.steadiness:
        return cardEffect_steadiness(m.lowResolveDamageReducePercent);
    }
  }

  String cardTradeoff(CardType type) {
    final CardModifier m = type.modifier;
    switch (type) {
      case CardType.strike:
        return cardTradeoff_strike(m.comboStaminaDelta);
      case CardType.guard:
        return cardTradeoff_guard(-m.goodGuardReductionDeltaPercent);
      case CardType.insight:
        return cardTradeoff_insight(-m.strikeWindowDeltaMs);
      case CardType.steadiness:
        return cardTradeoff_steadiness(-m.staminaRegenPercent);
    }
  }

  /// "Philippians 4:13" in this language.
  String reference(VerseRef ref) {
    final String name = bookName(ref.book.toString());
    final String book = name.isEmpty ? canonBooks[ref.book - 1] : name;
    return verseReference(book, ref.chapter, ref.verse);
  }
}
