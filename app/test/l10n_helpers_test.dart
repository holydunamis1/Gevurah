import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/models/verse_card_def.dart';
import 'package:gevurah/core/models/verse_ref.dart';
import 'package:gevurah/l10n/app_localizations.dart';
import 'package:gevurah/l10n/l10n_helpers.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('every struggle has a name and a tell, and they are real text', () {
    for (final s in StruggleCatalog.all) {
      expect(l.struggleName(s.id), isNot(s.id), reason: 'name for ${s.id}');
      expect(l.struggleTell(s.id), isNot(s.id), reason: 'tell for ${s.id}');
      expect(l.struggleTell(s.id).length, greaterThan(10));
    }
    expect(StruggleCatalog.all.length, 26);
    expect(l.struggleName('giving_up'), 'Giving Up');
    expect(l.struggleName('nope'), 'nope');
    expect(l.struggleTell('nope'), 'nope');
  });

  test('struggle names are unique', () {
    final Set<String> names = StruggleCatalog.all.map((s) => l.struggleName(s.id)).toSet();
    expect(names.length, 26);
  });

  test('every move kind, stance and card type has text', () {
    expect(MoveKind.values.map(l.moveName).toSet().length, MoveKind.values.length);
    expect(Stance.values.map(l.stanceName).toSet().length, Stance.values.length);
    expect(Stance.values.map(l.stanceHint).toSet().length, Stance.values.length);
    for (final CardType t in CardType.values) {
      expect(l.cardTypeName(t), isNotEmpty);
      expect(l.cardEffect(t), isNotEmpty);
      expect(l.cardTradeoff(t), isNotEmpty);
    }
  });

  test('card text carries the real numbers from the modifiers', () {
    expect(l.cardEffect(CardType.strike), 'Perfect strikes deal 25% more damage');
    expect(l.cardTradeoff(CardType.strike), 'Combos cost 2 more Stamina');
    expect(l.cardEffect(CardType.insight), 'Telegraphs last 60 ms longer');
    expect(l.cardTradeoff(CardType.insight), 'Strike windows are 20 ms narrower');
    expect(l.cardTradeoff(CardType.guard), 'Good guards reduce 10% less damage');
    expect(l.cardTradeoff(CardType.steadiness), 'Stamina recovers 20% slower');
  });

  test('every card reference formats with a real book name', () {
    for (final VerseCardDef c in CardCatalog.all) {
      final String text = l.reference(c.ref);
      expect(text, matches(RegExp(r'^\S.* \d+:\d+$')), reason: c.id);
      expect(text, startsWith(l.bookName(c.ref.book.toString())), reason: 'book name for ${c.id}');
    }
    expect(l.reference(VerseRef.parse('Philippians 4:13')), 'Philippians 4:13');
    expect(l.reference(VerseRef.parse('Genesis 1:1')), 'Genesis 1:1', reason: 'falls back to the canon name');
    expect(l.reference(VerseRef.parse('1 John 4:18')), '1 John 4:18');
  });

  test('HUD and tier labels fill their placeholders', () {
    expect(l.roundLabel(2, 3), 'Round 2 of 3');
    expect(l.tierLabel(4), 'Tier 4');
    expect(l.hudBreath, 'Breath');
  });
}
