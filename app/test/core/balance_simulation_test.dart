import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/card_catalog.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/logic/bout_simulator.dart';
import 'package:gevurah/core/logic/struggle_tuning.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/models/struggle_def.dart';

/// The balance gate. Seeded bots play many bouts per struggle through the same
/// resolver, AI and fight rules the game uses; win rates must stay inside the
/// bands below. A change that moves a struggle outside its band fails here, so
/// the numbers in StruggleTuning and the rules can only drift on purpose.
const int bouts = 300;

double winRate(StruggleDef s, BotProfile bot, {Stance stance = Stance.steady, List<String> cards = const <String>[]}) {
  int wins = 0;
  for (int i = 0; i < bouts; i++) {
    final FightConfig c = FightConfig(
      mode: FightMode.journey,
      struggleId: s.id,
      cardIds: cards,
      stance: stance,
      seed: 5000 + i,
    );
    if (BoutSimulator.run(c, s, bot).won) {
      wins++;
    }
  }
  return wins * 100 / bouts;
}

/// Allowed average-player win rate (percent) by tier; the final bout has its own.
const Map<int, List<double>> averageBands = <int, List<double>>{
  1: <double>[85, 99],
  2: <double>[72, 98],
  3: <double>[55, 92],
  4: <double>[38, 72],
};
const List<double> finalBand = <double>[32, 55];

void main() {
  final Map<String, Map<String, double>> table = <String, Map<String, double>>{};

  setUpAll(() {
    final StringBuffer out = StringBuffer('\nBALANCE TABLE (win percent, $bouts bouts each)\n');
    out.writeln('struggle            tier  novice  average  expert  | steady bold patient (average)');
    for (final StruggleDef s in StruggleCatalog.all) {
      final Map<String, double> row = <String, double>{
        'novice': winRate(s, BotProfile.novice),
        'average': winRate(s, BotProfile.average),
        'expert': winRate(s, BotProfile.expert),
        'steady': winRate(s, BotProfile.average, stance: Stance.steady),
        'bold': winRate(s, BotProfile.average, stance: Stance.bold),
        'patient': winRate(s, BotProfile.average, stance: Stance.patient),
      };
      table[s.id] = row;
      out.writeln('${s.id.padRight(20)}${s.tier.toString().padRight(6)}'
          '${row['novice']!.toStringAsFixed(0).padRight(8)}${row['average']!.toStringAsFixed(0).padRight(9)}'
          '${row['expert']!.toStringAsFixed(0).padRight(8)}| ${row['steady']!.toStringAsFixed(0).padRight(7)}'
          '${row['bold']!.toStringAsFixed(0).padRight(5)}${row['patient']!.toStringAsFixed(0)}');
    }
    // ignore: avoid_print
    print(out);
  });

  test('an average player lands inside the band for every struggle', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      final List<double> band = s.isFinal ? finalBand : averageBands[s.tier]!;
      final double rate = table[s.id]!['average']!;
      expect(rate, inInclusiveRange(band[0], band[1]), reason: '${s.id} (tier ${s.tier}) average win rate');
    }
  });

  test('a new player can win early fights and is pressed by late ones', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      final double rate = table[s.id]!['novice']!;
      if (s.tier == 1) {
        expect(rate, greaterThanOrEqualTo(20), reason: '${s.id} novice');
      }
      if (s.tier == 4) {
        expect(rate, lessThanOrEqualTo(20), reason: '${s.id} novice');
      }
    }
  });

  test('a practised player beats everything most of the time', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      expect(table[s.id]!['expert']!, greaterThanOrEqualTo(90), reason: '${s.id} expert');
    }
  });

  test('skill always helps: novice below average below or equal to expert', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      final Map<String, double> r = table[s.id]!;
      expect(r['novice']!, lessThanOrEqualTo(r['average']!), reason: s.id);
      expect(r['average']!, lessThanOrEqualTo(r['expert']!), reason: s.id);
    }
  });

  test('no stance sits far from the others', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      final Map<String, double> r = table[s.id]!;
      final List<double> v = <double>[r['steady']!, r['bold']!, r['patient']!]..sort();
      expect(v.last - v.first, lessThanOrEqualTo(25), reason: '${s.id} stance spread');
    }
  });

  test('no starter card changes the win rate wildly', () {
    final List<String> ids = <String>['pride', 'doubt', 'bitterness'];
    for (final String id in ids) {
      final StruggleDef s = StruggleCatalog.byId(id)!;
      final double base = table[id]!['average']!;
      for (final String card in CardCatalog.starterIds) {
        final double rate = winRate(s, BotProfile.average, cards: <String>[card]);
        expect((rate - base).abs(), lessThanOrEqualTo(30), reason: '$id with $card');
      }
    }
  });

  test('a bout is a pure function of its config', () {
    final StruggleDef s = StruggleCatalog.byId('pride')!;
    final FightConfig c = FightConfig(
      mode: FightMode.journey, struggleId: 'pride', cardIds: const <String>[], stance: Stance.bold, seed: 42);
    final BoutResult a = BoutSimulator.run(c, s, BotProfile.average);
    final BoutResult b = BoutSimulator.run(c, s, BotProfile.average);
    expect(a.state, b.state);
    expect(a.history.length, b.history.length);
    expect(a.history.length, lessThan(BoutSimulator.maxExchanges));
    expect(a.state.isFinished, true);
    expect(a.state.end, isNotNull);
  });

  test('every bout ends before the safety cap', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      for (int i = 0; i < 20; i++) {
        final FightConfig c = FightConfig(
          mode: FightMode.journey, struggleId: s.id, cardIds: const <String>[], stance: Stance.steady, seed: 900 + i);
        final BoutResult r = BoutSimulator.run(c, s, BotProfile.novice);
        expect(r.history.length, lessThan(BoutSimulator.maxExchanges), reason: s.id);
        expect(r.state.phase, FightPhase.finished);
      }
    }
  });

  test('tuning values are positive and every struggle has one', () {
    for (final StruggleDef s in StruggleCatalog.all) {
      expect(StruggleTuning.incomingDamagePercent(s), greaterThan(0), reason: s.id);
    }
    for (final String id in StruggleTuning.damagePercentOverrides.keys) {
      expect(StruggleCatalog.byId(id), isNotNull, reason: 'override for unknown struggle $id');
    }
  });
}
