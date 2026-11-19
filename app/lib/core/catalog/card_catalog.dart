import '../models/verse_card_def.dart';
import '../models/verse_ref.dart';

VerseCardDef _card(String id, String ref, CardType type, [String? struggleId]) =>
    VerseCardDef(id: id, ref: VerseRef.parse(ref), type: type, earnedByStruggleId: struggleId);

/// Every verse card. Four starters, then one card earned by defeating each of
/// the 26 struggles. References only; the text comes from the bundled verses.
abstract final class CardCatalog {
  static final List<VerseCardDef> starters = List<VerseCardDef>.unmodifiable(<VerseCardDef>[
    _card('starter_strike', 'Philippians 4:13', CardType.strike),
    _card('starter_guard', 'Psalms 18:2', CardType.guard),
    _card('starter_insight', 'Psalms 119:105', CardType.insight),
    _card('starter_steadiness', 'Isaiah 40:31', CardType.steadiness),
  ]);

  static final List<VerseCardDef> earned = List<VerseCardDef>.unmodifiable(<VerseCardDef>[
    _card('fear', 'Isaiah 41:10', CardType.guard, 'fear'),
    _card('worry', 'Matthew 6:34', CardType.steadiness, 'worry'),
    _card('anger', 'James 1:19', CardType.insight, 'anger'),
    _card('impatience', 'Psalms 27:14', CardType.steadiness, 'impatience'),
    _card('loneliness', 'Deuteronomy 31:6', CardType.guard, 'loneliness'),
    _card('discouragement', 'Joshua 1:9', CardType.strike, 'discouragement'),
    _card('exhaustion', 'Matthew 11:28', CardType.steadiness, 'exhaustion'),
    _card('envy', 'Proverbs 14:30', CardType.insight, 'envy'),
    _card('doubt', 'Mark 9:24', CardType.insight, 'doubt'),
    _card('temptation', '1 Corinthians 10:13', CardType.guard, 'temptation'),
    _card('rejection', 'Psalms 27:10', CardType.steadiness, 'rejection'),
    _card('bitterness', 'Ephesians 4:31', CardType.insight, 'bitterness'),
    _card('pride', 'Proverbs 16:18', CardType.guard, 'pride'),
    _card('shame', 'Romans 10:11', CardType.steadiness, 'shame'),
    _card('failure', 'Proverbs 24:16', CardType.strike, 'failure'),
    _card('giving_up', 'Ephesians 6:13', CardType.steadiness, 'giving_up'),
    _card('comparison', 'Galatians 6:4', CardType.insight, 'comparison'),
    _card('procrastination', 'Ephesians 5:16', CardType.insight, 'procrastination'),
    _card('distraction', 'Hebrews 12:1', CardType.strike, 'distraction'),
    _card('regret', 'Philippians 3:13', CardType.strike, 'regret'),
    _card('indecision', 'James 1:5', CardType.insight, 'indecision'),
    _card('money_pressure', 'Hebrews 13:5', CardType.steadiness, 'money_pressure'),
    _card('perfectionism', '2 Corinthians 12:9', CardType.guard, 'perfectionism'),
    _card('overwhelm', 'Psalms 61:2', CardType.steadiness, 'overwhelm'),
    _card('unforgiveness', 'Colossians 3:13', CardType.guard, 'unforgiveness'),
    _card('complaining', 'Philippians 2:14', CardType.strike, 'complaining'),
  ]);

  static final List<VerseCardDef> all =
      List<VerseCardDef>.unmodifiable(<VerseCardDef>[...starters, ...earned]);

  static final Map<String, VerseCardDef> _byId = <String, VerseCardDef>{
    for (final VerseCardDef c in all) c.id: c,
  };

  static VerseCardDef? byId(String id) => _byId[id];

  /// The card earned by defeating [struggleId], or null.
  static VerseCardDef? earnedBy(String struggleId) {
    for (final VerseCardDef c in earned) {
      if (c.earnedByStruggleId == struggleId) {
        return c;
      }
    }
    return null;
  }

  /// The ids of the cards a new player owns.
  static List<String> get starterIds => starters.map((VerseCardDef c) => c.id).toList(growable: false);
}
