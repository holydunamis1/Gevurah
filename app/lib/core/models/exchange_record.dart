import 'beat_offset.dart';
import 'exchange_outcome.dart';
import 'model_utils.dart';
import 'move_def.dart';

/// How the player answers an incoming move.
enum Response {
  /// Tap: absorb the move.
  guard,

  /// Swipe sideways: avoid the move.
  slip,

  /// Do nothing: take the move in full.
  takeIt,
}

/// What the player does with an opening after a good or perfect response.
enum OpeningAction { none, strike, combo }

/// One exchange of a bout, kept so a bout can be replayed exactly.
class ExchangeRecord {
  const ExchangeRecord({
    required this.index,
    required this.round,
    required this.move,
    required this.response,
    required this.offset,
    required this.outcome,
    this.counter = OpeningAction.none,
    this.strikeOffset,
  });

  final int index;
  final int round;
  final MoveDef move;
  final Response response;

  /// Timing of the response against the beat.
  final BeatOffset offset;
  final ExchangeOutcome outcome;

  /// The action taken in the opening, if one was available.
  final OpeningAction counter;

  /// Timing of the counter against its beat; null when there was no counter.
  final BeatOffset? strikeOffset;

  int get damageDealt => outcome.damageDealt;
  int get damageTaken => outcome.damageTaken;

  Map<String, Object?> toJson() => <String, Object?>{
        'index': index,
        'round': round,
        'move': move.toJson(),
        'response': response.name,
        'offset': offset.toJson(),
        'outcome': outcome.toJson(),
        'counter': counter.name,
        'strikeOffset': strikeOffset?.toJson(),
      };

  factory ExchangeRecord.fromJson(Map<String, Object?> json) {
    final Object? so = json['strikeOffset'];
    BeatOffset? strikeOffset;
    if (so != null) {
      if (so is! Map<String, Object?>) {
        throw FormatException('Expected an object at "strikeOffset", got $so');
      }
      strikeOffset = BeatOffset.fromJson(so);
    }
    final Object? counterValue = json['counter'];
    return ExchangeRecord(
      index: readInt(json, 'index'),
      round: readInt(json, 'round'),
      move: MoveDef.fromJson(readMap(json, 'move')),
      response: readEnum(Response.values, json, 'response'),
      offset: BeatOffset.fromJson(readMap(json, 'offset')),
      outcome: ExchangeOutcome.fromJson(readMap(json, 'outcome')),
      counter: counterValue == null ? OpeningAction.none : readEnum(OpeningAction.values, json, 'counter'),
      strikeOffset: strikeOffset,
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
        other.outcome == outcome &&
        other.counter == counter &&
        other.strikeOffset == strikeOffset;
  }

  @override
  int get hashCode => Object.hash(index, round, move, response, offset, outcome, counter, strikeOffset);

  @override
  String toString() => 'ExchangeRecord($index, ${move.id}, ${response.name}, $offset)';
}
