import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/catalog/struggle_catalog.dart';
import 'package:gevurah/core/logic/bout_simulator.dart';
import 'package:gevurah/core/models/fight_config.dart';
import 'package:gevurah/core/models/stance.dart';
import 'package:gevurah/core/models/struggle_def.dart';

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

void main() {
  test('print the balance table', () {
    final StringBuffer out = StringBuffer('\nBALANCE REPORT (win percent, $bouts bouts each)\n');
    out.writeln('struggle            tier  novice  average  expert  | steady bold patient (average)');
    for (final StruggleDef s in StruggleCatalog.all) {
      final String row = '${s.id.padRight(20)}${s.tier.toString().padRight(6)}'
          '${winRate(s, BotProfile.novice).toStringAsFixed(0).padRight(8)}'
          '${winRate(s, BotProfile.average).toStringAsFixed(0).padRight(9)}'
          '${winRate(s, BotProfile.expert).toStringAsFixed(0).padRight(8)}| '
          '${winRate(s, BotProfile.average, stance: Stance.steady).toStringAsFixed(0).padRight(7)}'
          '${winRate(s, BotProfile.average, stance: Stance.bold).toStringAsFixed(0).padRight(5)}'
          '${winRate(s, BotProfile.average, stance: Stance.patient).toStringAsFixed(0)}';
      out.writeln(row);
    }
    // ignore: avoid_print
    print(out);
    expect(true, true);
  });
}
