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
    this.extraBreath = 0,
    this.extraStamina = 0,
    this.isRetry = false,
    this.easy = false,
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

  /// Rewarded-ad bonuses chosen before the bout: more Breath charges, and more
  /// starting Stamina (Endurance only). Never applied to the Daily Bout.
  final int extraBreath;
  final int extraStamina;

  /// True for the one retry a player may earn after a loss.
  final bool isRetry;

  /// The one-tap game: any tap blocks, the counter fires by itself, and Stamina
  /// never runs out. Set for normal play; the Training lessons keep every action.
  final bool easy;

  FightConfig copyWith({
    FightMode? mode,
    String? struggleId,
    List<String>? cardIds,
    Stance? stance,
    int? seed,
    Difficulty? difficulty,
    bool? timingAssist,
    int? extraBreath,
    int? extraStamina,
    bool? isRetry,
    bool? easy,
  }) {
    return FightConfig(
      mode: mode ?? this.mode,
      struggleId: struggleId ?? this.struggleId,
      cardIds: cardIds ?? this.cardIds,
      stance: stance ?? this.stance,
      seed: seed ?? this.seed,
      difficulty: difficulty ?? this.difficulty,
      timingAssist: timingAssist ?? this.timingAssist,
      extraBreath: extraBreath ?? this.extraBreath,
      extraStamina: extraStamina ?? this.extraStamina,
      isRetry: isRetry ?? this.isRetry,
      easy: easy ?? this.easy,
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
        if (extraBreath != 0) 'extraBreath': extraBreath,
        if (extraStamina != 0) 'extraStamina': extraStamina,
        if (isRetry) 'isRetry': isRetry,
        if (easy) 'easy': easy,
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
      extraBreath: json['extraBreath'] is int ? json['extraBreath']! as int : 0,
      extraStamina: json['extraStamina'] is int ? json['extraStamina']! as int : 0,
      isRetry: json['isRetry'] == true,
      easy: json['easy'] == true,
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
        other.timingAssist == timingAssist &&
        other.extraBreath == extraBreath &&
        other.extraStamina == extraStamina &&
        other.isRetry == isRetry &&
        other.easy == easy;
  }

  @override
  int get hashCode => Object.hash(mode, struggleId, listHash(cardIds), stance, seed, difficulty, timingAssist, extraBreath, extraStamina, isRetry, easy);

  @override
  String toString() => 'FightConfig(${mode.name}, $struggleId, seed $seed)';
}
