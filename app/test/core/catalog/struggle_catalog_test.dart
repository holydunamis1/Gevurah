import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/models/move_def.dart';
import 'package:gevurah/core/models/struggle_def.dart';

void main() {
  test('there are 16 career struggles and 10 trials, 26 in all', () {
    expect(StruggleCatalog.career.length, 16);
    expect(StruggleCatalog.trials.length, 10);
    expect(StruggleCatalog.all.length, 26);
  });

  test('ids are unique and look up correctly', () {
    final Set<String> ids = StruggleCatalog.all.map((StruggleDef s) => s.id).toSet();
    expect(ids.length, 26);
    for (final StruggleDef s in StruggleCatalog.all) {
      expect(StruggleCatalog.byId(s.id), same(s));
    }
    expect(StruggleCatalog.byId('nope'), isNull);
  });

  test('the career has four struggles in each of four tiers', () {
    for (int tier = 1; tier <= 4; tier++) {
      expect(StruggleCatalog.careerTier(tier).length, 4, reason: 'tier $tier');
    }
  });

  test('exactly one final bout, in tier 4, named Giving Up', () {
    final List<StruggleDef> finals = StruggleCatalog.all.where((StruggleDef s) => s.isFinal).toList();
    expect(finals.length, 1);
    expect(finals.single.id, 'giving_up');
    expect(finals.single.tier, 4);
    expect(finals.single.track, StruggleTrack.career);
    expect(StruggleCatalog.finalBout.id, 'giving_up');
  });

  test('the career order matches the design table', () {
    expect(
      StruggleCatalog.career.map((StruggleDef s) => s.id).toList(),
      <String>[
        'fear', 'worry', 'anger', 'impatience',
        'loneliness', 'discouragement', 'exhaustion', 'envy',
        'doubt', 'temptation', 'rejection', 'bitterness',
        'pride', 'shame', 'failure', 'giving_up',
      ],
    );
  });

  test('the trials are the ten extras and Grief is not an opponent', () {
    expect(
      StruggleCatalog.trials.map((StruggleDef s) => s.id).toSet(),
      <String>{
        'comparison', 'procrastination', 'distraction', 'regret', 'indecision',
        'money_pressure', 'perfectionism', 'overwhelm', 'unforgiveness', 'complaining',
      },
    );
    expect(StruggleCatalog.byId('grief'), isNull);
    for (final StruggleDef s in StruggleCatalog.trials) {
      expect(s.track, StruggleTrack.trials);
      expect(s.isFinal, isFalse);
    }
  });

  test('every struggle has a valid tier, Weight, traits and moves', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      expect(s.tier, inInclusiveRange(1, 4), reason: s.id);
      expect(s.weight, greaterThan(0), reason: s.id);
      expect(s.traits, isNotEmpty, reason: s.id);
      expect(s.moves, isNotEmpty, reason: s.id);
    }
  });

  test('move ids are unique across the whole catalog and every move is sensible', () {
    final List<String> ids = <String>[];
    for (final StruggleDef s in StruggleCatalog.all) {
      for (final MoveDef m in s.moves) {
        ids.add(m.id);
        expect(m.id.startsWith('${s.id}_'), isTrue, reason: m.id);
        expect(m.telegraphMs, greaterThanOrEqualTo(400), reason: m.id);
        expect(m.hits, greaterThanOrEqualTo(1), reason: m.id);
        expect(m.damage, greaterThanOrEqualTo(0), reason: m.id);
        if (m.kind != MoveKind.fake) {
          expect(m.damage > 0 || m.staminaDrain > 0, isTrue, reason: '${m.id} must do something');
        }
      }
    }
    expect(ids.toSet().length, ids.length);
  });

  test('Weight rises with tier and the final bout is the heaviest', () {
    int weightOf(String id) => StruggleCatalog.byId(id)!.weight;
    expect(weightOf('fear'), lessThan(weightOf('loneliness')));
    expect(weightOf('loneliness'), lessThan(weightOf('doubt')));
    expect(weightOf('doubt'), lessThan(weightOf('pride')));
    for (final StruggleDef s in StruggleCatalog.all) {
      if (!s.isFinal) {
        expect(s.weight, lessThan(StruggleCatalog.finalBout.weight), reason: s.id);
      }
    }
  });

  test('the tells match the design', () {
    StruggleDef s(String id) => StruggleCatalog.byId(id)!;
    expect(s('fear').hasTrait(StruggleTrait.erratic), isTrue);
    expect(s('anger').moves.any((MoveDef m) => m.kind == MoveKind.heavy), isTrue);
    expect(s('discouragement').moves.every((MoveDef m) => m.staminaDrain > 0), isTrue);
    expect(s('doubt').moves.where((MoveDef m) => m.kind == MoveKind.fake).length, greaterThanOrEqualTo(2));
    expect(s('temptation').moves.any((MoveDef m) => m.kind == MoveKind.bait), isTrue);
    expect(s('pride').hasTrait(StruggleTrait.countering), isTrue);
    expect(s('failure').hasTrait(StruggleTrait.resilient), isTrue);
    expect(s('shame').hasTrait(StruggleTrait.guardLow), isTrue);
  });

  test('impatience attacks before a normal telegraph would finish', () {
    final StruggleDef impatience = StruggleCatalog.byId('impatience')!;
    final StruggleDef fear = StruggleCatalog.byId('fear')!;
    final int fastestImpatience = impatience.moves.map((MoveDef m) => m.telegraphMs).reduce((int a, int b) => a < b ? a : b);
    final int slowestFear = fear.moves.map((MoveDef m) => m.telegraphMs).reduce((int a, int b) => a > b ? a : b);
    expect(fastestImpatience, lessThan(slowestFear));
  });

  test('every struggle survives a JSON round trip', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      expect(StruggleDef.fromJson(s.toJson()), s, reason: s.id);
    }
  });

  test('telegraphs get shorter in higher tiers (typical move)', () {
    double avg(int tier) {
      final List<int> all = StruggleCatalog.career
          .where((StruggleDef s) => s.tier == tier)
          .expand((StruggleDef s) => s.moves)
          .map((MoveDef m) => m.telegraphMs)
          .toList();
      return all.reduce((int a, int b) => a + b) / all.length;
    }

    expect(avg(1), greaterThan(avg(2)));
    expect(avg(2), greaterThan(avg(3)));
    expect(avg(3), greaterThan(avg(4)));
  });
}
