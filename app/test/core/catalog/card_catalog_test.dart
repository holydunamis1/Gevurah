import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/models/struggle_def.dart';
import 'package:gevurah/core/models/verse_card_def.dart';

void main() {
  test('four starters (one per type) and one earned card per struggle', () {
    expect(CardCatalog.starters.length, 4);
    expect(CardCatalog.starters.map((VerseCardDef c) => c.type).toSet(), CardType.values.toSet());
    expect(CardCatalog.earned.length, 26);
    expect(CardCatalog.all.length, 30);
  });

  test('card ids are unique and look up correctly', () {
    expect(CardCatalog.all.map((VerseCardDef c) => c.id).toSet().length, 30);
    for (final VerseCardDef c in CardCatalog.all) {
      expect(CardCatalog.byId(c.id), same(c));
    }
    expect(CardCatalog.byId('nope'), isNull);
  });

  test('every struggle earns exactly one card and every earned card points at a real struggle', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      final VerseCardDef? c = CardCatalog.earnedBy(s.id);
      expect(c, isNotNull, reason: s.id);
      expect(c!.earnedByStruggleId, s.id);
    }
    for (final VerseCardDef c in CardCatalog.earned) {
      expect(StruggleCatalog.byId(c.earnedByStruggleId!), isNotNull, reason: c.id);
    }
  });

  test('starters are starters and earned cards are not', () {
    expect(CardCatalog.starters.every((VerseCardDef c) => c.isStarter), isTrue);
    expect(CardCatalog.earned.every((VerseCardDef c) => !c.isStarter), isTrue);
    expect(CardCatalog.starterIds.length, 4);
  });

  test('the final bout card carries Ephesians 6:13', () {
    expect(CardCatalog.earnedBy('giving_up')!.ref.toString(), 'Ephesians 6:13');
  });

  test('every type is used by earned cards, so loadouts have real choices', () {
    for (final CardType t in CardType.values) {
      expect(CardCatalog.earned.where((VerseCardDef c) => c.type == t).length, greaterThanOrEqualTo(4), reason: t.name);
    }
  });

  test('every card survives a JSON round trip', () {
    for (final VerseCardDef c in CardCatalog.all) {
      expect(VerseCardDef.fromJson(c.toJson()), c, reason: c.id);
    }
  });
}
