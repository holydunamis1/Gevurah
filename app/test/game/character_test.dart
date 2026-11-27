import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/game/components/character.dart';

void main() {
  test('every struggle has its own drawn character', () {
    final Set<String> looks = <String>{};
    for (final s in StruggleCatalog.all) {
      expect(CharacterSpec.ids, contains(s.id));
      final CharacterSpec c = CharacterSpec.forId(s.id);
      looks.add('${c.body}${c.kind}${c.eyes}${c.mouth}${c.extras}');
    }
    expect(looks.length, StruggleCatalog.all.length);
  });

  test('every character paints in every mood without throwing', () {
    for (final String id in CharacterSpec.ids) {
      for (final CharacterMood m in const <CharacterMood>[
        CharacterMood(),
        CharacterMood(tell: 0.7, time: 1.2),
        CharacterMood(hurt: true),
        CharacterMood(lunge: 0.5, time: 3),
      ]) {
        final PictureRecorder rec = PictureRecorder();
        CharacterPainter.paint(Canvas(rec), CharacterSpec.forId(id), 60, m, glow: const Color(0xFFFFD166));
        rec.endRecording();
      }
    }
  });

  test('an unknown id still gets a character', () {
    expect(CharacterSpec.forId('nope'), isNotNull);
  });
}
