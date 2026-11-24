import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/game/tuning.dart';

void main() {
  test('every sound id has a WAV file under assets/audio', () {
    for (final String id in GameTuning.allSounds) {
      final File f = File('assets/audio/$id.wav');
      expect(f.existsSync(), isTrue, reason: id);
      final List<int> head = f.readAsBytesSync().sublist(0, 12);
      expect(String.fromCharCodes(head.sublist(0, 4)), 'RIFF', reason: id);
      expect(String.fromCharCodes(head.sublist(8, 12)), 'WAVE', reason: id);
    }
  });

  test('no audio file is left without an id', () {
    final Set<String> files = Directory('assets/audio').listSync().map((FileSystemEntity e) => e.uri.pathSegments.last.replaceAll('.wav', '')).toSet();
    expect(files, GameTuning.allSounds.toSet());
  });

  test('every move kind has a tell sound; fakes and baits sound like a strike', () {
    for (final MoveKind k in MoveKind.values) {
      expect(GameTuning.allSounds, contains(GameTuning.tellSound(k)));
    }
    expect(GameTuning.tellSound(MoveKind.fake), GameTuning.tellSound(MoveKind.strike));
    expect(GameTuning.tellSound(MoveKind.bait), GameTuning.tellSound(MoveKind.strike));
    expect(GameTuning.tellSound(MoveKind.heavy), GameTuning.soundTellHeavy);
    expect(GameTuning.tellSound(MoveKind.flurry), GameTuning.soundTellFlurry);
  });
}
