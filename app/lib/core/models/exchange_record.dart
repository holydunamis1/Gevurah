import 'beat_offset.dart';
import 'exchange_outcome.dart';
import 'model_utils.dart';
import 'move_def.dart';

/// What the player did in response to a telegraphed move.
enum Response {
  /// Tap on the beat to block.
  guard,

  /// Swipe sideways to dodge.
  slip,

  /// No response in time; the move lands.
  takeIt,
}

/// One finished exchange, kept as the bout's history.
class ExchangeRecord {
  const ExchangeRecord({
    required this.index,
    required this.round,
    required this.move,
    required this.response,
    required this.offset,
    required this.outcome,
  });

  /// Counted from zero across the whole bout.
  final int index;
  final int round;
  final MoveDef move;
  final Response response;
  final BeatOffset offset;
  final ExchangeOutcome outcome;

  int get damageDealt => outcome.damageDealt;
  int get damageTaken => outcome.damageTaken;

  Map<String, Object?> toJson() => <String, Object?>{
        'index': index,
        'round': round,
        'move': move.toJson(),
        'response': response.name,
        'offset': offset.toJson(),
        'outcome': outcome.toJson(),
      };

  factory ExchangeRecord.fromJson(Map<String, Object?> json) {
    return ExchangeRecord(
      index: readInt(json, 'index'),
      round: readInt(json, 'round'),
      move: MoveDef.fromJson(readMap(json, 'move')),
      response: readEnum(Response.values, json, 'response'),
      offset: BeatOffset.fromJson(readMap(json, 'offset')),
      outcome: ExchangeOutcome.fromJson(readMap(json, 'outcome')),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExchangeRecord &&
        other.index == index &&
        other.round == round &&
        other.move == move &&
        other.response == response &&
        other.offset == offset &&
        other.outcome == outcome;
  }

  @override
  int get hashCode => Object.hash(index, round, move, response, offset, outcome);

  @override
  String toString() => 'ExchangeRecord(#$index, ${move.id}, ${response.name})';
}
