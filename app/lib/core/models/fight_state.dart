import 'model_utils.dart';
import 'player_state.dart';

/// Where the bout is within a round.
enum FightPhase { telegraph, response, opening, resolve, corner, tenCount, finished }

/// How a finished bout ended.
enum FightEnd {
  /// The struggle's Weight reached zero: it was knocked down.
  struggleDefeated,

  /// The player was down three times.
  playerDown,

  /// Round three ended; the player was ahead on points.
  decisionWon,

  /// Round three ended; the struggle was ahead on points.
  decisionLost,
}

/// An immutable snapshot of a bout. The fight rules map one snapshot and one
/// exchange record to the next.
class FightState {
  const FightState({
    required this.round,
    required this.startingWeight,
    required this.weight,
    required this.player,
    required this.exchangeIndex,
    required this.phase,
    this.end,
  });

  static const int roundsPerBout = 3;

  /// The state at the start of a bout against a struggle of [startingWeight].
  const FightState.initial(int startingWeight)
      : round = 1,
        startingWeight = startingWeight,
        weight = startingWeight,
        player = const PlayerState.initial(),
        exchangeIndex = 0,
        phase = FightPhase.telegraph,
        end = null;

  /// 1 to [roundsPerBout].
  final int round;
  final int startingWeight;

  /// The struggle's current Weight.
  final int weight;
  final PlayerState player;

  /// Index of the next exchange, counted from zero across the whole bout.
  final int exchangeIndex;
  final FightPhase phase;

  /// Set once the bout is finished.
  final FightEnd? end;

  bool get isFinished => end != null;

  /// Weight removed so far.
  int get weightRemoved => startingWeight - weight;

  FightState copyWith({
    int? round,
    int? startingWeight,
    int? weight,
    PlayerState? player,
    int? exchangeIndex,
    FightPhase? phase,
    FightEnd? end,
  }) {
    return FightState(
      round: round ?? this.round,
      startingWeight: startingWeight ?? this.startingWeight,
      weight: weight ?? this.weight,
      player: player ?? this.player,
      exchangeIndex: exchangeIndex ?? this.exchangeIndex,
      phase: phase ?? this.phase,
      end: end ?? this.end,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'round': round,
        'startingWeight': startingWeight,
        'weight': weight,
        'player': player.toJson(),
        'exchangeIndex': exchangeIndex,
        'phase': phase.name,
        'end': end?.name,
      };

  factory FightState.fromJson(Map<String, Object?> json) {
    final Object? endValue = json['end'];
    FightEnd? end;
    if (endValue != null) {
      if (endValue is! String) {
        throw FormatException('Expected an end name, got $endValue');
      }
      end = FightEnd.values.byName(endValue);
    }
    return FightState(
      round: readInt(json, 'round'),
      startingWeight: readInt(json, 'startingWeight'),
      weight: readInt(json, 'weight'),
      player: PlayerState.fromJson(readMap(json, 'player')),
      exchangeIndex: readInt(json, 'exchangeIndex'),
      phase: readEnum(FightPhase.values, json, 'phase'),
      end: end,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FightState &&
        other.round == round &&
        other.startingWeight == startingWeight &&
        other.weight == weight &&
        other.player == player &&
        other.exchangeIndex == exchangeIndex &&
        other.phase == phase &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(round, startingWeight, weight, player, exchangeIndex, phase, end);

  @override
  String toString() => 'FightState(round $round, weight $weight, ${player.toString()}, ${phase.name})';
}
