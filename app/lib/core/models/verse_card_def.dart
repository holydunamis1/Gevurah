import 'model_utils.dart';
import 'verse_ref.dart';

/// The four kinds of verse card.
enum CardType { strike, guard, insight, steadiness }

/// What a card type changes and what it costs. All numbers are tuning starting
/// values; zero means the card does not touch that value.
class CardModifier {
  const CardModifier({
    this.perfectStrikeDamagePercent = 0,
    this.comboStaminaDelta = 0,
    this.perfectGuardStaminaReturn = 0,
    this.goodGuardReductionDeltaPercent = 0,
    this.telegraphDeltaMs = 0,
    this.strikeWindowDeltaMs = 0,
    this.lowResolveDamageReducePercent = 0,
    this.staminaRegenPercent = 0,
  });

  /// Strike: perfect strikes deal this many percent more damage.
  final int perfectStrikeDamagePercent;

  /// Strike trade-off: Combo costs this much more Stamina.
  final int comboStaminaDelta;

  /// Guard: Stamina returned by a perfect guard.
  final int perfectGuardStaminaReturn;

  /// Guard trade-off: change to the damage reduction of a good guard (negative = less).
  final int goodGuardReductionDeltaPercent;

  /// Insight: milliseconds added to telegraphs seen.
  final int telegraphDeltaMs;

  /// Insight trade-off: change to strike windows in ms (negative = narrower).
  final int strikeWindowDeltaMs;

  /// Steadiness: damage taken drops this percent while Resolve is below 30 percent.
  final int lowResolveDamageReducePercent;

  /// Steadiness trade-off: change to Stamina regeneration percent (negative = slower).
  final int staminaRegenPercent;

  @override
  bool operator ==(Object other) =>
      other is CardModifier &&
      other.perfectStrikeDamagePercent == perfectStrikeDamagePercent &&
      other.comboStaminaDelta == comboStaminaDelta &&
      other.perfectGuardStaminaReturn == perfectGuardStaminaReturn &&
      other.goodGuardReductionDeltaPercent == goodGuardReductionDeltaPercent &&
      other.telegraphDeltaMs == telegraphDeltaMs &&
      other.strikeWindowDeltaMs == strikeWindowDeltaMs &&
      other.lowResolveDamageReducePercent == lowResolveDamageReducePercent &&
      other.staminaRegenPercent == staminaRegenPercent;

  @override
  int get hashCode => Object.hash(
        perfectStrikeDamagePercent,
        comboStaminaDelta,
        perfectGuardStaminaReturn,
        goodGuardReductionDeltaPercent,
        telegraphDeltaMs,
        strikeWindowDeltaMs,
        lowResolveDamageReducePercent,
        staminaRegenPercent,
      );
}

/// The modifier of each card type (blueprint section 2).
extension CardTypeModifier on CardType {
  CardModifier get modifier {
    switch (this) {
      case CardType.strike:
        return const CardModifier(perfectStrikeDamagePercent: 25, comboStaminaDelta: 2);
      case CardType.guard:
        return const CardModifier(perfectGuardStaminaReturn: 6, goodGuardReductionDeltaPercent: -10);
      case CardType.insight:
        return const CardModifier(telegraphDeltaMs: 60, strikeWindowDeltaMs: -20);
      case CardType.steadiness:
        return const CardModifier(lowResolveDamageReducePercent: 25, staminaRegenPercent: -20);
    }
  }
}

/// One equippable verse card. The verse text is not stored here: the card holds
/// a reference and the text is read from the bundled verses.
class VerseCardDef {
  const VerseCardDef({
    required this.id,
    required this.ref,
    required this.type,
    this.earnedByStruggleId,
  });

  factory VerseCardDef.fromJson(Map<String, Object?> json) => VerseCardDef(
        id: readString(json, 'id'),
        ref: VerseRef.fromJson(readMap(json, 'ref')),
        type: readEnum(CardType.values, json, 'type'),
        earnedByStruggleId: readOptString(json, 'earnedByStruggleId'),
      );

  final String id;
  final VerseRef ref;
  final CardType type;

  /// The struggle whose defeat earns this card, or null for a starter card.
  final String? earnedByStruggleId;

  bool get isStarter => earnedByStruggleId == null;

  CardModifier get modifier => type.modifier;

  /// Localization keys for the card's name and effect text.
  String get nameKey => 'card_$id';
  String get effectKey => 'card_type_${type.name}';
  String get tradeoffKey => 'card_type_${type.name}_tradeoff';

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'ref': ref.toJson(),
        'type': type.name,
        'earnedByStruggleId': earnedByStruggleId,
      };

  @override
  bool operator ==(Object other) =>
      other is VerseCardDef &&
      other.id == id &&
      other.ref == ref &&
      other.type == type &&
      other.earnedByStruggleId == earnedByStruggleId;

  @override
  int get hashCode => Object.hash(id, ref, type, earnedByStruggleId);
}
