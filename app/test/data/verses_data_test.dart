import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/models/curated_verse.dart';
import 'package:gevurah/core/models/license_notice.dart';
import 'package:gevurah/core/models/verse_card_def.dart';

const List<String> _languages = <String>['en', 'es', 'fr', 'de', 'pt', 'ar', 'hi', 'zh', 'he'];

Map<String, Object?> _readJson(String path) {
  final Object? decoded = jsonDecode(File(path).readAsStringSync());
  return decoded! as Map<String, Object?>;
}

void main() {
  final List<CuratedVerse> curated = <CuratedVerse>[
    for (final Object? v in (_readJson('assets/verses/curated.json')['verses']! as List<Object?>))
      CuratedVerse.fromJson(v! as Map<String, Object?>),
  ];

  test('the curated list parses and has enough verses for every moment', () {
    expect(curated, isNotEmpty);
    expect(curated.map((CuratedVerse c) => c.id).toSet().length, curated.length);
    final Map<VerseMoment, int> counts = <VerseMoment, int>{
      for (final VerseMoment m in VerseMoment.values) m: curated.where((CuratedVerse c) => c.fits(m)).length,
    };
    expect(counts[VerseMoment.preBout], greaterThanOrEqualTo(26));
    expect(counts[VerseMoment.corner], greaterThanOrEqualTo(8));
    expect(counts[VerseMoment.tenCount], greaterThanOrEqualTo(6));
    expect(counts[VerseMoment.win], greaterThanOrEqualTo(8));
    expect(counts[VerseMoment.loss], greaterThanOrEqualTo(8));
    expect(counts[VerseMoment.daily], greaterThanOrEqualTo(50));
    expect(counts[VerseMoment.card], greaterThanOrEqualTo(30));
  });

  test('every curated verse resolves in every bundled language', () {
    for (final String lang in _languages) {
      final Map<String, Object?> bundle = _readJson('assets/verses/$lang.json');
      expect(bundle['language'], lang);
      final Map<String, Object?> verses = bundle['verses']! as Map<String, Object?>;
      for (final CuratedVerse c in curated) {
        final Object? text = verses[c.ref.key];
        expect(text, isA<String>(), reason: '$lang ${c.id}');
        expect((text! as String).trim(), isNotEmpty, reason: '$lang ${c.id}');
      }
      expect(verses.length, curated.length, reason: lang);
    }
  });

  test('every card verse and every struggle has a curated verse in the right moments', () {
    final Set<String> cardKeys = <String>{
      for (final CuratedVerse c in curated.where((CuratedVerse c) => c.fits(VerseMoment.card))) c.ref.key,
    };
    for (final VerseCardDef card in CardCatalog.all) {
      expect(cardKeys, contains(card.ref.key), reason: card.id);
    }
    final Set<String> preBoutIds = <String>{
      for (final CuratedVerse c in curated.where((CuratedVerse c) => c.fits(VerseMoment.preBout))) c.id,
    };
    for (final String id in StruggleCatalog.all.map((s) => s.id)) {
      expect(preBoutIds, contains('prebout_$id'), reason: id);
    }
  });

  test('every language has a licence notice that parses, with attribution where required', () {
    for (final String lang in _languages) {
      final LicenseNotice n = LicenseNotice.fromJson(_readJson('assets/licenses/$lang.json'));
      expect(n.sourceName, isNotEmpty, reason: lang);
      expect(n.license, isNotEmpty, reason: lang);
      expect(n.link, startsWith('https://'), reason: lang);
      if (n.license.contains('Creative Commons')) {
        expect(n.attribution, isNotEmpty, reason: lang);
      }
    }
  });
}
