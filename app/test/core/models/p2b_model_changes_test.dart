import 'package:flutter_test/flutter_test.dart';
import 'package:gevurah/core/models/beat_offset.dart';
import 'package:gevurah/core/models/exchange_outcome.dart';
import 'package:gevurah/core/models/exchange_record.dart';
import 'package:gevurah/core/models/fight_state.dart';
import 'package:gevurah/core/models/move_def.dart';

void main() {
  const ExchangeOutcome outcome = ExchangeOutcome(
    quality: Quality.perfect,
    damageTaken: 0,
    damageDealt: 10,
    staminaChange: -9,
    opening: true,
  );
  const MoveDef move = MoveDef(id: 'm', kind: MoveKind.strike, telegraphMs: 900, damage: 6);

  test('ExchangeRecord keeps the counter and its timing through JSON', () {
    const ExchangeRecord r = ExchangeRecord(
      index: 1,
      round: 1,
      move: move,
      response: Response.guard,
      offset: BeatOffset(5),
      outcome: outcome,
      counter: OpeningAction.combo,
      strikeOffset: BeatOffset(-12),
    );
    expect(ExchangeRecord.fromJson(r.toJson()), r);
    expect(ExchangeRecord.fromJson(r.toJson()).counter, OpeningAction.combo);
    expect(ExchangeRecord.fromJson(r.toJson()).strikeOffset, const BeatOffset(-12));
  });

  test('ExchangeRecord defaults to no counter and reads old JSON without the new fields', () {
    const ExchangeRecord r = ExchangeRecord(
      index: 0,
      round: 1,
      move: move,
      response: Response.slip,
      offset: BeatOffset(0),
      outcome: outcome,
    );
    expect(r.counter, OpeningAction.none);
    expect(r.strikeOffset, isNull);
    final Map<String, Object?> old = r.toJson()
      ..remove('counter')
      ..remove('strikeOffset');
    expect(ExchangeRecord.fromJson(old), r);
  });

  test('FightState counts struggle rises and reads old JSON without it', () {
    final FightState s = const FightState.initial(100).copyWith(struggleRises: 1);
    expect(s.struggleRises, 1);
    expect(FightState.fromJson(s.toJson()), s);
    final Map<String, Object?> old = s.toJson()..remove('struggleRises');
    expect(FightState.fromJson(old).struggleRises, 0);
    expect(const FightState.initial(100).struggleRises, 0);
  });
}
