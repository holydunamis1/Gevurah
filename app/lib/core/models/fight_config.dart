import 'model_utils.dart';
import 'stance.dart';

/// Where a bout is played from.
enum FightMode { journey, trials, sparring, daily, endurance, training }

/// Difficulty for Sparring. Other modes use [standard].
enum Difficulty { gentle, standard, hard }

/// Everything needed to replay a bout exactly. A bout is a pure function of
/// this config and the player's timing inputs.
class FightConfig {
  const FightConfig({
    required this.mode,
    required this.struggleId,
    required this.cardIds,
    required this.stance,
    required this.seed,
    this.difficulty = Difficulty.standard,
    this.timingAssist = false,
  });

  final FightMode mode;
  final String struggleId;

  /// The equipped verse card ids (up to three). A Loadout converts to these.
  final List<String> cardIds;
  final Stance stance;

  /// Seeds the struggle AI. The Daily Bout seed comes from the date.
  final int seed;
  final Difficulty difficulty;

  /// The Timing assist setting: widens every timing window.
  final bool timingAssist;

  FightConfig copyWith({
    FightMode? mode,
    String? struggleId,
    List<String>? cardIds,
    Stance? stance,
    int? seed,
    Difficulty? difficulty,
    bool? timingAssist,
  }) {
    return FightConfig(
      mode: mode ?? this.mode,
      struggleId: struggleId ?? this.struggleId,
      cardIds: cardIds ?? this.cardIds,
      stance: stance ?? this.stance,
      seed: seed ?? this.seed,
      difficulty: difficulty ?? this.difficulty,
      timingAssist: timingAssist ?? this.timingAssist,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'mode': mode.name,
        'struggleId': struggleId,
        'cardIds': cardIds,
        'stance': stance.name,
        'seed': seed,
        'difficulty': difficulty.name,
        'timingAssist': timingAssist,
      };

  factory FightConfig.fromJson(Map<String, Object?> json) {
    final List<String> ids = <String>[];
    for (final Object? v in readList(json, 'cardIds')) {
      if (v is! String) {
        throw FormatException('Expected a card id, got $v');
      }
      ids.add(v);
    }
    return FightConfig(
      mode: readEnum(FightMode.values, json, 'mode'),
      struggleId: readString(json, 'struggleId'),
      cardIds: ids,
      stance: readEnum(Stance.values, json, 'stance'),
      seed: readInt(json, 'seed'),
      difficulty: readEnum(Difficulty.values, json, 'difficulty'),
      timingAssist: readBool(json, 'timingAssist'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FightConfig &&
        other.mode == mode &&
        other.struggleId == struggleId &&
        listEq(other.cardIds, cardIds) &&
        other.stance == stance &&
        other.seed == seed &&
        other.difficulty == difficulty &&
        other.timingAssist == timingAssist;
  }

  @override
  int get hashCode => Object.hash(mode, struggleId, listHash(cardIds), stance, seed, difficulty, timingAssist);

  @override
  String toString() => 'FightConfig(${mode.name}, $struggleId, seed $seed)';
}
